#include "predictions.h"
#include "ascad_meta.h"
#include <stdint.h>
#include <stdio.h>

#define BYTE 2  

void perform_attacks(float *avg_rank_out);
void perform_attack_sorted(float *rank_evol_out);

float avg_rank[NB_TRACES];
float sorted_rank[NB_TRACES];

volatile struct {
    uint8_t correct_key_byte;
    float   final_rank;
    float   min_rank;
    int     ntge;          
    int     ntge_sorted;   
} result;

int main(void) {
    /* --- Orijinal saldiri (shuffle, 100 atak ortalama) --- */
    perform_attacks(avg_rank);

    result.correct_key_byte = real_key[BYTE];
    result.final_rank       = avg_rank[NB_TRACES - 1];

    float min_rk = avg_rank[0];
    int   ntge   = -1;
    for (int i = 0; i < NB_TRACES; i++) {
        if (avg_rank[i] < min_rk)
            min_rk = avg_rank[i];
        if (ntge < 0 && avg_rank[i] == 0.0f)
            ntge = i + 1;
    }
    result.min_rank = min_rk;
    result.ntge     = ntge;

    /* --- Confidence siralama ile tek saldiri --- */
    perform_attack_sorted(sorted_rank);

    int ntge_sorted = -1;
    for (int i = 0; i < NB_TRACES; i++) {
        if (ntge_sorted < 0 && sorted_rank[i] == 0.0f)
            ntge_sorted = i + 1;
    }
    result.ntge_sorted = ntge_sorted;

#ifndef NO_PRINTF
    printf("Correct key byte : 0x%02X\n", result.correct_key_byte);
    printf("Final rank       : %.2f\n",   result.final_rank);
    printf("Min rank         : %.2f\n",   result.min_rank);
    if (result.ntge > 0)
        printf("NTGE (shuffle)   : %d traces\n", result.ntge);
    else
        printf("Rank 0 NOT reached (shuffle) within %d traces\n", NB_TRACES);
    if (result.ntge_sorted > 0)
        printf("NTGE (sorted)    : %d traces\n", result.ntge_sorted);
    else
        printf("Rank 0 NOT reached (sorted) within %d traces\n", NB_TRACES);
#endif

    return 0 ;
}
