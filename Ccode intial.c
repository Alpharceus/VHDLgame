#include <stdio.h>
#include <stdlib.h>
#include <time.h>

// Constants for the game
#define MAX_FUNDS 100000
#define MAX_PUBLIC_OPINION 100
#define MAX_TRUST 100
#define DONATION_1 1000
#define DONATION_2 2000
#define DONATION_3 5000
#define DONATION_4 10000

// Function prototypes
int rollDice();
void approachDonor(int *funds);
void makeDecision(int *funds, int *publicOpinion, int *publicTrust);
void faceOpponent(int *publicOpinion);
void dealWithMedia(int *publicOpinion);
void checkPublicTrust(int *publicTrust);

int main() {
    int funds = 0;
    int publicOpinion = MAX_PUBLIC_OPINION;
    int publicTrust = MAX_TRUST;
    int gameRunning = 1;

    // Initialize random number generator
    srand(time(NULL));

    printf("Welcome to The Presidential Race: Funding the Dream\n");

    while (gameRunning) {
        // Approach Donor
        approachDonor(&funds);

        // Make strategic decisions
        makeDecision(&funds, &publicOpinion, &publicTrust);

        // Face opponents
        faceOpponent(&publicOpinion);

        // Deal with media
        dealWithMedia(&publicOpinion);

        // Check public trust
        checkPublicTrust(&publicTrust);

        // Check winning condition
        if (publicTrust >= 80) {
            printf("Congratulations! You have won the presidency!\n");
            gameRunning = 0;
        }

        // Check losing condition
        if (publicOpinion <= 0 || funds <= 0 || publicTrust <= 0) {
            printf("You have lost the presidential race.\n");
            gameRunning = 0;
        }
    }

    return 0;
}

int rollDice() {
    return rand() % 100 + 1; // Returns a number between 1 and 100
}

void approachDonor(int *funds) {
    int roll = rollDice();
    if (roll <= 50) {
        *funds += DONATION_1;
    } else if (roll <= 80) {
        *funds += DONATION_2;
    } else if (roll <= 95) {
        *funds += DONATION_3;
    } else {
        *funds += DONATION_4;
    }
    printf("You received a donation. Current funds: $%d\n", *funds);
}

void makeDecision(int *funds, int *publicOpinion, int *publicTrust) {
    int choice;
    printf("Choose your campaign strategy:\n");
    printf("1. Advertising\n2. Outreach Programs\n3. Hosting Rallies\n");
    printf("Enter your choice: ");
    scanf("%d", &choice);

    switch(choice) {
        case 1:
            *funds -= 5000;
            *publicOpinion += 5;
            break;
        case 2:
            *funds -= 3000;
            *publicTrust += 5;
            break;
        case 3:
            *funds -= 7000;
            *publicOpinion += 10;
            break;
        default:
            printf("Invalid choice. Lost a turn.\n");
            break;
    }

    // Deal with lobbyists
    int deal;
    printf("A lobbyist approaches you with a proposition. Do you accept? (1 for yes, 0 for no): ");
    scanf("%d", &deal);

    if (deal) {
        *funds += 10000; // Gain funds from lobbyists
        *publicTrust -= 10; // Lose some public trust
    }
}

void faceOpponent(int *publicOpinion) {
    int smearCampaign = rollDice();
    if (smearCampaign <= 20) { // 20% chance the opponent runs a smear campaign
        *publicOpinion -= 20;
        printf("Your opponent has run a smear campaign against you! Public opinion decreased.\n");
    }
}

void dealWithMedia(int *publicOpinion) {
    int mediaEvent = rollDice();
    if (mediaEvent <= 50) { // 50% chance the media misrepresents you
        *publicOpinion -= 10;
        printf("The media has misrepresented your policies! Public opinion decreased.\n");
    }
}

void checkPublicTrust(int *publicTrust) {
    int scandal = rollDice();
    if (scandal <= 10) { // 10% chance of a scandal
        *publicTrust -= 20;
        printf("A scandal has surfaced! Public trust decreased.\n");
    }
}

