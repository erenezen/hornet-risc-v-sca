#include <math.h>
#include <stdint.h>
#include <string.h>

#include "aes_sbox.h"
#include "ascad_meta.h"
#include "predictions.h"

#define BYTE       2
#define EPS        1e-40f
#define NB_ATTACKS 100   

/* ---------- LCG random (shuffle icin) ---------- */
static uint32_t lcg_state = 12345u;

static uint32_t lcg_rand(void) {
    lcg_state = lcg_state * 1664525u + 1013904223u;
    return lcg_state;
}

static void shuffle_indices(uint16_t *idx, int n) {
    for (int i = n - 1; i > 0; i--) {
        int j = (int)(lcg_rand() % (uint32_t)(i + 1));
        uint16_t tmp = idx[i];
        idx[i]       = idx[j];
        idx[j]       = tmp;
    }
}

/* ---------- Confidence hesaplama ---------- */
static float trace_confidence[NB_TRACES];

/* Her trace icin max(predictions[t][c]) degerini hesapla */
static void compute_confidence(void) {
    for (int t = 0; t < NB_TRACES; t++) {
        float mx = predictions[t][0];
        for (int c = 1; c < NB_CLASSES; c++) {
            if (predictions[t][c] > mx)
                mx = predictions[t][c];
        }
        trace_confidence[t] = mx;
    }
}

/* Confidence'a gore azalan sirada sirala (en iyi trace once) */
static void sort_by_confidence(uint16_t *idx, int n) {
    for (int i = 1; i < n; i++) {
        uint16_t key = idx[i];
        float key_conf = trace_confidence[key];
        int j = i - 1;
        while (j >= 0 && trace_confidence[idx[j]] < key_conf) {
            idx[j + 1] = idx[j];
            j--;
        }
        idx[j + 1] = key;
    }
}

/* ---------- Rank hesaplama ---------- */
static int compute_rank(const float *key_log_prob, uint8_t correct_key) {
    float ref  = key_log_prob[correct_key];
    int   rank = 0;
    for (int k = 0; k < 256; k++) {
        if (key_log_prob[k] > ref)
            rank++;
    }
    return rank;
}

static void rank_compute(const uint16_t *idx, float *rank_evol) {
    float key_log_prob[256];
    for (int k = 0; k < 256; k++)
        key_log_prob[k] = 0.0f;

    for (int i = 0; i < NB_TRACES; i++) {
        uint16_t t = idx[i];   

        for (int k = 0; k < 256; k++) {
            uint8_t sbox_out    = AES_Sbox[k ^ plaintext[t][BYTE]];
            key_log_prob[k]    += logf(predictions[t][sbox_out] + EPS);
        }

        rank_evol[i] = (float)compute_rank(key_log_prob, real_key[BYTE]);
    }
}

/* ---------- Orijinal saldiri (shuffle, ortalama) ---------- */
void perform_attacks(float *avg_rank_out) {
    static uint16_t idx[NB_TRACES];
    static float    rank_evol[NB_TRACES];

    for (int i = 0; i < NB_TRACES; i++)
        avg_rank_out[i] = 0.0f;

    for (int a = 0; a < NB_ATTACKS; a++) {
        for (int i = 0; i < NB_TRACES; i++)
            idx[i] = (uint16_t)i;
        shuffle_indices(idx, NB_TRACES);

        rank_compute(idx, rank_evol);

        for (int i = 0; i < NB_TRACES; i++)
            avg_rank_out[i] += rank_evol[i];
    }

    for (int i = 0; i < NB_TRACES; i++)
        avg_rank_out[i] /= (float)NB_ATTACKS;
}

/* ---------- Confidence siralama ile tek saldiri ---------- */
void perform_attack_sorted(float *rank_evol_out) {
    static uint16_t idx[NB_TRACES];

    compute_confidence();
    
    for (int i = 0; i < NB_TRACES; i++)
        idx[i] = (uint16_t)i;
    
    sort_by_confidence(idx, NB_TRACES);
    rank_compute(idx, rank_evol_out);
}
