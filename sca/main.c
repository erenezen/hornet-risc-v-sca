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
    result.correct_key_byte = real_key[BYTE];

    /* --- Shuffle saldiri (100 atak ortalama) --- */
    perform_attacks(avg_rank);

    result.final_rank = avg_rank[NB_TRACES - 1];
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

    /* --- Sorted saldiri --- */
    perform_attack_sorted(sorted_rank);

    int ntge_sorted = -1;
    for (int i = 0; i < NB_TRACES; i++) {
        if (ntge_sorted < 0 && sorted_rank[i] == 0.0f)
            ntge_sorted = i + 1;
    }
    result.ntge_sorted = ntge_sorted;

#ifndef NO_PRINTF
    printf("=== SCA Attack Results ===\n");
    printf("Target key byte : 0x%02X (BYTE=%d)\n", result.correct_key_byte, BYTE);
    printf("Total traces    : %d\n\n", NB_TRACES);

    /* Rank evolution tablosu */
    int milestones[] = {1,2,3,5,8,10,15,18,20,25,30,40,50,75,100,150,200,250,300,350,400};
    int nm = sizeof(milestones)/sizeof(milestones[0]);

    printf("Trace |  Shuffle  |  Sorted\n");
    printf("------+-----------+--------\n");
    for (int m = 0; m < nm; m++) {
        int i = milestones[m] - 1;  /* 0-indexed */
        if (i >= NB_TRACES) break;
        printf("%5d | %7.1f   | %7.1f\n", i + 1, avg_rank[i], sorted_rank[i]);
    }

    printf("\n--- Summary ---\n");
    printf("Final rank (shuffle) : %.2f\n", result.final_rank);
    printf("Min rank (shuffle)   : %.2f\n", result.min_rank);

    if (result.ntge > 0)
        printf("NTGE (shuffle)       : %d traces\n", result.ntge);
    else
        printf("NTGE (shuffle)       : NOT reached within %d traces\n", NB_TRACES);

    if (result.ntge_sorted > 0)
        printf("NTGE (sorted)        : %d traces\n", result.ntge_sorted);
    else
        printf("NTGE (sorted)        : NOT reached within %d traces\n", NB_TRACES);
#endif

    return 0;
}

