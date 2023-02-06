#ifndef _TZ_OPERATION_STATE_H
#define _TZ_OPERATION_STATE_H	1

#include "num_state.h"

typedef enum {
  TZ_OPERATION_TAG_REVEAL      = 107,
  TZ_OPERATION_TAG_TRANSACTION = 108,
  TZ_OPERATION_TAG_ORIGINATION = 109,
  TZ_OPERATION_TAG_DELEGATION  = 110,
  TZ_OPERATION_TAG_SET_DEPOSIT = 112,
  TZ_OPERATION_TAG_UPDATE_CK   = 114
} tz_operation_tag;

typedef enum {
  TZ_OPERATION_STEP_MAGIC,
  TZ_OPERATION_STEP_BRANCH,
  TZ_OPERATION_STEP_BATCH,
  TZ_OPERATION_STEP_TAG,
  TZ_OPERATION_STEP_SIZE,
  TZ_OPERATION_STEP_OPERATION,
  TZ_OPERATION_STEP_PRINT,
  TZ_OPERATION_STEP_READ_NUM,
  TZ_OPERATION_STEP_READ_PK,
  TZ_OPERATION_STEP_READ_BYTES,
  TZ_OPERATION_STEP_READ_ENTRYPOINT,
  TZ_OPERATION_STEP_READ_MICHELINE
} tz_operation_parser_step_kind;

typedef enum {
  TZ_OPERATION_FIELD_SKIP, // not for use in field descriptors
  TZ_OPERATION_FIELD_INT,
  TZ_OPERATION_FIELD_NAT,
  TZ_OPERATION_FIELD_AMOUNT,
  TZ_OPERATION_FIELD_SOURCE,
  TZ_OPERATION_FIELD_PKH,
  TZ_OPERATION_FIELD_PK,
  TZ_OPERATION_FIELD_DESTINATION,
  TZ_OPERATION_FIELD_PARAMETER,
  TZ_OPERATION_FIELD_OPH,
  TZ_OPERATION_FIELD_BH
} tz_operation_field_kind;


typedef struct {
  char *name;
  tz_operation_field_kind kind : 4;
  uint8_t required : 1, skip : 1, display_none : 1;
} tz_operation_field_descriptor;

typedef struct {
  tz_operation_tag tag;
  char *name;
  const tz_operation_field_descriptor *fields;
} tz_operation_descriptor;

typedef struct {
  tz_operation_parser_step_kind step : 4;
  uint16_t stop;
  union {
    struct {
      uint16_t size;
    } step_size;
    struct {
      const tz_operation_descriptor *descriptor;
      uint8_t field;
    } step_operation;
    struct {
      char *str;
    } step_print;
    struct {
      uint16_t ofs;
      uint16_t len;
      tz_operation_field_kind kind : 4;
      uint8_t skip : 1;
    } step_read_bytes;
    struct {
      tz_num_parser_regs state;
      tz_operation_field_kind kind : 4;
      uint8_t skip : 1, natural : 1;
    } step_read_num;
    struct {
      uint16_t ofs;
      uint8_t skip : 1;
    } step_read_entrypoint;
    struct {
      char *name;
      uint8_t inited : 1;
      uint8_t skip : 1;
      char *pattern_entrypoint;
    } step_read_micheline;
  };
} tz_operation_parser_frame;

#define TZ_OPERATION_STACK_DEPTH 6

typedef struct {
  tz_operation_parser_frame stack[TZ_OPERATION_STACK_DEPTH];
  tz_operation_parser_frame *frame; // init == stack, NULL when done
  uint8_t seen_reveal : 1; // check at most one reveal
  uint8_t source[22];      // check consistent source in batch
  uint8_t destination[22]; // saved for entrypoint dispatch
  uint16_t batch_index;    // to print a sequence number
} tz_operation_state;

#endif /* operation_parser.h */
