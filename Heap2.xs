#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

static int
cmp_nv (SV *a, SV *b, SV *data)
{
  if (SvROK (a) && SvTYPE (SvRV (a)) == SVt_PVAV) a = *av_fetch ((AV *)SvRV (a), 0, 1);
  if (SvROK (b) && SvTYPE (SvRV (b)) == SVt_PVAV) b = *av_fetch ((AV *)SvRV (b), 0, 1);

  return SvNV (a) > SvNV (b);
}

static int
cmp_sv (SV *a, SV *b, SV *data)
{
  if (SvROK (a) && SvTYPE (SvRV (a)) == SVt_PVAV) a = *av_fetch ((AV *)SvRV (a), 0, 1);
  if (SvROK (b) && SvTYPE (SvRV (b)) == SVt_PVAV) b = *av_fetch ((AV *)SvRV (b), 0, 1);

  return sv_cmp(a, b) > 0;
}

static int
cmp_custom (SV *a, SV *b, SV *data)
{
  SV *old_a, *old_b;
  int ret;
  dSP;

  if (!PL_firstgv)  PL_firstgv  = gv_fetchpv ("a", 1, SVt_PV);
  if (!PL_secondgv) PL_secondgv = gv_fetchpv ("b", 1, SVt_PV);

  old_a = GvSV (PL_firstgv);
  old_b = GvSV (PL_secondgv);

  GvSV (PL_firstgv)  = a;
  GvSV (PL_secondgv) = b;

  PUSHMARK (SP);
  PUTBACK;
  ret = call_sv (data, G_SCALAR | G_NOARGS | G_EVAL);
  SPAGAIN;

  GvSV (PL_firstgv)  = old_a;
  GvSV (PL_secondgv) = old_b;

  if (SvTRUE (ERRSV))
    croak (NULL);

  if (ret != 1)
    croak ("sort function must return exactly one return value");

  return POPi >= 0;
}

typedef int (*f_cmp)(SV *, SV *, SV *);

static AV *
array (SV *ref)
{
  if (SvROK (ref) && SvTYPE (SvRV (ref)) == SVt_PVAV)
    return (AV *)SvRV (ref);

  croak ("argument 'heap' must be an array");
}

#define geta(i) (*av_fetch (av, (i), 1))
#define gt(a,b) cmp ((a), (b), data)
#define seta(i,v) seta_helper (av_fetch (av, (i), 1), v)

static void
seta_helper (SV **i, SV *v)
{
  SvREFCNT_dec (*i);
  *i = v;
}

static void
push_heap_aux (AV *av, f_cmp cmp, SV *data, int hole_index, int top, SV *value)
{
  int parent = (hole_index - 1) / 2;

  while (hole_index > top && gt (geta (parent), value))
    {
      seta (hole_index, SvREFCNT_inc (geta (parent)));
      hole_index = parent;
      parent = (hole_index - 1) / 2;
    }

  seta (hole_index, value);
}

static void
adjust_heap (AV *av, f_cmp cmp, SV *data, int hole_index, int len, SV *elem)
{
  int top = hole_index;
  int second_child = 2 * (hole_index + 1);

  while (second_child < len)
    {
      if (gt (geta (second_child), geta (second_child - 1)))
        second_child--;

      seta (hole_index, SvREFCNT_inc (geta (second_child)));
      hole_index = second_child;
      second_child = 2 * (second_child + 1);
    }

  if (second_child == len)
    {
      seta (hole_index, SvREFCNT_inc (geta (second_child - 1)));
      hole_index = second_child - 1;
    }

  push_heap_aux (av, cmp, data, hole_index, top, elem);
}

static void
make_heap (AV *av, f_cmp cmp, SV *data)
{
  if (av_len (av) > 0)
    {
      int len = av_len (av) + 1;
      int parent = (len - 2) / 2;

      do {
          adjust_heap (av, cmp, data, parent, len, SvREFCNT_inc (geta (parent)));
      } while (parent--);
    }
}

static void
push_heap (AV *av, f_cmp cmp, SV *data, SV *elem)
{
  elem = newSVsv (elem);
  av_push (av, elem);
  push_heap_aux (av, cmp, data, av_len (av), 0, SvREFCNT_inc (elem));
}

static SV *
pop_heap (AV *av, f_cmp cmp, SV *data)
{
  if (av_len (av) < 0)
    return &PL_sv_undef;
  else if (av_len (av) == 0)
    return av_pop (av);
  else
    {
      SV *result = newSVsv (geta (0));
      SV *top = av_pop (av);

      adjust_heap (av, cmp, data, 0, av_len (av) + 1, top);

      return result;
    }
}

MODULE = Array::Heap2		PACKAGE = Array::Heap2

void
make_heap (heap)
	SV *	heap
        PROTOTYPE: \@
        CODE:
        make_heap (array (heap), cmp_nv, 0);

void
make_heap_lex (heap)
	SV *	heap
        PROTOTYPE: \@
        CODE:
        make_heap (array (heap), cmp_sv, 0);

void
make_heap_cmp (cmp, heap)
	SV *	cmp
	SV *	heap
        PROTOTYPE: &\@
        CODE:
        make_heap (array (heap), cmp_custom, cmp);

void
push_heap (heap, ...)
	SV *	heap
        PROTOTYPE: \@@
        CODE:
        int i;
        for (i = 1; i < items; i++)
          push_heap (array (heap), cmp_nv, 0, ST(i));

void
push_heap_lex (heap, ...)
	SV *	heap
        PROTOTYPE: \@@
        CODE:
        int i;
        for (i = 1; i < items; i++)
          push_heap (array (heap), cmp_sv, 0, ST(i));

void
push_heap_cmp (cmp, heap, ...)
	SV *	cmp
	SV *	heap
        PROTOTYPE: &\@@
        CODE:
        int i;
        for (i = 1; i < items; i++)
          push_heap (array (heap), cmp_custom, cmp, ST(i));

SV *
pop_heap (heap)
	SV *	heap
        PROTOTYPE: \@
        CODE:
        RETVAL = pop_heap (array (heap), cmp_nv, 0);
        OUTPUT:
        RETVAL

SV *
pop_heap_lex (heap)
	SV *	heap
        PROTOTYPE: \@
        CODE:
        RETVAL = pop_heap (array (heap), cmp_sv, 0);
        OUTPUT:
        RETVAL

SV *
pop_heap_cmp (cmp, heap)
	SV *	cmp
	SV *	heap
        PROTOTYPE: &\@
        CODE:
        RETVAL = pop_heap (array (heap), cmp_custom, cmp);
        OUTPUT:
        RETVAL


