#ifndef _TZ_MICHELINE_STATE_H
#define _TZ_MICHELINE_STATE_H	1

#include "num_state.h"

#define TZ_MICHELINE_STACK_DEPTH 45

typedef enum {
  TZ_MICHELINE_TAG_INT,
  TZ_MICHELINE_TAG_STRING,
  TZ_MICHELINE_TAG_SEQ,
  TZ_MICHELINE_TAG_PRIM_0_NOANNOTS,
  TZ_MICHELINE_TAG_PRIM_0_ANNOTS,
  TZ_MICHELINE_TAG_PRIM_1_NOANNOTS,
  TZ_MICHELINE_TAG_PRIM_1_ANNOTS,
  TZ_MICHELINE_TAG_PRIM_2_NOANNOTS,
  TZ_MICHELINE_TAG_PRIM_2_ANNOTS,
  TZ_MICHELINE_TAG_PRIM_N,
  TZ_MICHELINE_TAG_BYTES
} tz_micheline_tag;

typedef enum {
  TZ_MICHELINE_STEP_TAG,
  TZ_MICHELINE_STEP_PRIM_OP,
  TZ_MICHELINE_STEP_PRIM_NAME,
  TZ_MICHELINE_STEP_PRIM,
  TZ_MICHELINE_STEP_SIZE,
  TZ_MICHELINE_STEP_SEQ,
  TZ_MICHELINE_STEP_CAPTURING,
  TZ_MICHELINE_STEP_LISTING,
  TZ_MICHELINE_STEP_BRANCHING,
  TZ_MICHELINE_STEP_BYTES,
  TZ_MICHELINE_STEP_STRING,
  TZ_MICHELINE_STEP_ANNOT,
  TZ_MICHELINE_STEP_INT,
  TZ_MICHELINE_STEP_PRINT_INT,
  TZ_MICHELINE_STEP_CAPTURE_BYTES,
  TZ_MICHELINE_STEP_PRINT_CAPTURE
} tz_micheline_parser_step_kind;

typedef enum {
  TZ_CAP_STREAM_ANY = 0,
  TZ_CAP_STREAM_BYTES,
  TZ_CAP_STREAM_INT,
  TZ_CAP_STREAM_STRING,
  TZ_CAP_ADDRESS,
  TZ_CAP_LIST = 62,
  TZ_CAP_OR
} tz_micheline_capture_kind;

typedef struct {
  tz_micheline_parser_step_kind step : 4;
  uint16_t stop;
  uint16_t pat_stop;
  union {
    struct {
      uint16_t size;
    } step_size; // TZ_MICHELINE_STEP_SIZE
    struct {
      uint8_t first : 1;
    } step_seq; // TZ_MICHELINE_STEP_SEQ
    struct {
      uint8_t first : 1, has_rem_half: 1;
      uint8_t rem_half;
    } step_bytes; // TZ_MICHELINE_STEP_BYTES
    struct {
      uint8_t first : 1;
    } step_string; // TZ_MICHELINE_STEP_STRING
    struct {
      uint8_t first : 1;
    } step_annot; // TZ_MICHELINE_STEP_ANNOT
    tz_num_parser_regs step_int; // TZ_MICHELINE_STEP_INT, TZ_MICHELINE_STEP_PRINT_INT
    struct {
      uint8_t op;
      uint8_t ofs;
      uint8_t nargs : 2, wrap : 1, spc : 1, annot : 1, first : 1;
    } step_prim; // TZ_MICHELINE_STEP_PRIM_OP, TZ_MICHELINE_STEP_PRIM_NAME, TZ_MICHELINE_STEP_PRIM
    struct {
      int ofs;
    } step_capture; // TZ_MICHELINE_STEP_CAPTURE_BYTES, TZ_MICHELINE_STEP_PRINT_CAPTURE
    struct {
      uint16_t saved_pat_ofs;
      uint16_t seq;
    } step_listing; // TZ_MICHELINE_STEP_LISTING
    struct {
      uint16_t pat_ofs_after;
      uint8_t tag;
    } step_branching; // TZ_MICHELINE_STEP_BRANCHING
    tz_micheline_capture_kind step_capturing; // TZ_MICHELINE_STEP_CAPTURING
  };
} tz_micheline_parser_frame;

typedef struct {
  tz_micheline_parser_frame stack[TZ_MICHELINE_STACK_DEPTH];
  tz_micheline_parser_frame *frame; // init == stack, NULL when done
  const uint8_t* pat; // NULL if no pattern, in case capture.frame == stack
  int pat_ofs;
  size_t pat_len;
  bool capturing;
} tz_micheline_state;

#endif /* micheline_state.h */
