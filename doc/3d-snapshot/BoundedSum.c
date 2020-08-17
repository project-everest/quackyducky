

#include "BoundedSum.h"

/*
Auto-generated field identifier for error reporting
*/
#define BOUNDEDSUM__LEFT ((uint64_t)1U)

/*
Auto-generated field identifier for error reporting
*/
#define BOUNDEDSUM__RIGHT ((uint64_t)2U)

/*
Auto-generated field identifier for error reporting
*/
#define MYSUM__BOUND ((uint64_t)3U)

static inline uint64_t ValidateBoundedSumLeft(InputBuffer Input, uint64_t StartPosition)
/*++
    Internal helper function:
        Validator for field _boundedSum_left
        of type _boundedSum
--*/
{
  /* SNIPPET_START: boundedSum */
  /* Checking that we have enough space for a ULONG, i.e., 4 bytes */
  uint64_t endPositionOrError;
  if (((uint64_t)Input.len - StartPosition) < (uint64_t)4U)
  {
    endPositionOrError = EVERPARSE_VALIDATOR_ERROR_NOT_ENOUGH_DATA;
  }
  else
  {
    endPositionOrError = StartPosition + (uint64_t)4U;
  }
  return EverParseMaybeSetErrorCode(endPositionOrError, StartPosition, BOUNDEDSUM__LEFT);
}

static inline uint64_t
ValidateBoundedSumRight(
  uint32_t Bound,
  uint32_t Left,
  InputBuffer Input,
  uint64_t StartPosition
)
/*++
    Internal helper function:
        Validator for field _boundedSum_right
        of type _boundedSum
--*/
{
  /* Validating field right */
  /* Checking that we have enough space for a ULONG, i.e., 4 bytes */
  uint64_t positionAfterBoundedSumRight;
  if (((uint64_t)Input.len - StartPosition) < (uint64_t)4U)
  {
    positionAfterBoundedSumRight = EVERPARSE_VALIDATOR_ERROR_NOT_ENOUGH_DATA;
  }
  else
  {
    positionAfterBoundedSumRight = StartPosition + (uint64_t)4U;
  }
  uint64_t endPositionOrError;
  if (EverParseIsError(positionAfterBoundedSumRight))
  {
    endPositionOrError = positionAfterBoundedSumRight;
  }
  else
  {
    /* reading field value */
    uint32_t boundedSumRight = Load32Le(Input.base + (uint32_t)StartPosition);
    /* start: checking constraint */
    BOOLEAN boundedSumRightConstraintIsOk = Left <= Bound && boundedSumRight <= (Bound - Left);
    /* end: checking constraint */
    endPositionOrError =
      EverParseCheckConstraintOk(boundedSumRightConstraintIsOk,
        positionAfterBoundedSumRight);
  }
  return EverParseMaybeSetErrorCode(endPositionOrError, StartPosition, BOUNDEDSUM__RIGHT);
}

uint64_t
BoundedSumValidateBoundedSum(uint32_t Bound, InputBuffer Input, uint64_t StartPosition)
{
  /* Field _boundedSum_left */
  uint64_t positionAfterleft = ValidateBoundedSumLeft(Input, StartPosition);
  if (EverParseIsError(positionAfterleft))
  {
    return positionAfterleft;
  }
  uint32_t left = Load32Le(Input.base + (uint32_t)StartPosition);
  /* Field _boundedSum_right */
  return ValidateBoundedSumRight(Bound, left, Input, positionAfterleft);
}

static inline uint64_t ValidateMySumBound(InputBuffer Input, uint64_t StartPosition)
/*++
    Internal helper function:
        Validator for field mySum_bound
        of type mySum
--*/
{
  /* Validating field bound */
  /* Checking that we have enough space for a ULONG, i.e., 4 bytes */
  uint64_t endPositionOrError;
  if (((uint64_t)Input.len - StartPosition) < (uint64_t)4U)
  {
    endPositionOrError = EVERPARSE_VALIDATOR_ERROR_NOT_ENOUGH_DATA;
  }
  else
  {
    endPositionOrError = StartPosition + (uint64_t)4U;
  }
  return EverParseMaybeSetErrorCode(endPositionOrError, StartPosition, MYSUM__BOUND);
}

static inline uint64_t
ValidateMySumSum(uint32_t Bound, InputBuffer Input, uint64_t StartPosition)
/*++
    Internal helper function:
        Validator for field mySum_sum
        of type mySum
--*/
{
  /* Validating field sum */
  return BoundedSumValidateBoundedSum(Bound, Input, StartPosition);
}

uint64_t BoundedSumValidateMySum(InputBuffer Input, uint64_t StartPosition)
{
  /* Field mySum_bound */
  uint64_t positionAfterbound = ValidateMySumBound(Input, StartPosition);
  if (EverParseIsError(positionAfterbound))
  {
    return positionAfterbound;
  }
  uint32_t bound = Load32Le(Input.base + (uint32_t)StartPosition);
  /* Field mySum_sum */
  return ValidateMySumSum(bound, Input, positionAfterbound);
}

