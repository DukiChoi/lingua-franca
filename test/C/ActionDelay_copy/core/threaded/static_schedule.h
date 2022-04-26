/* Should be auto-generated */

// The total number of reactions
static const int reaction_count = 4;

// Number of semaphores needed
static const int num_semaphores = 0;

// Schedule 1 (most generic): all signals present.
static const inst_t s1_w1[] = { {.inst='e', .op=0 }, {.inst='e', .op=1 }, {.inst='s', .op=0 } };
static const inst_t s1_w2[] = { {.inst='e', .op=2 }, {.inst='e', .op=3 }, {.inst='s', .op=0 } };
static const inst_t s1_w3[] = { {.inst='s', .op=0 } };

static const inst_t* s1[] = { s1_w1, s1_w2, s1_w3 };

static const inst_t** static_schedules[] = { s1 };

static const uint32_t s1_length[] = {3, 3, 1};
static const uint32_t* schedule_lengths[] = { s1_length };