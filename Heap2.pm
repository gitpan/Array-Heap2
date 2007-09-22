=head1 NAME

Array::Heap2 - treat perl arrays as heaps (priority queues)

=head1 SYNOPSIS

 use Array::Heap2;

=head1 DESCRIPTION

There are a multitude of heap and heap-like modules on CPAN, you might
want to search for /Heap/ and /Priority/ to find many. They implement more
or less fancy datastructures that might well be what you are looking for.

This module takes a different approach: It exports functions (i.e. not
object orientation) that are loosely modeled after the C++ STL's heap
functions. They all take an array as argument, just like perl's built-in
functions C<push>, C<pop> etc.

The implementation itself is in C for maximum speed (although I doubt it
makes that much of a difference).

=head1 FUNCTIONS

All of the following functions are being exported by default.

=over 4

=cut

package Array::Heap2;

BEGIN {
   $VERSION = "1.1";

   require XSLoader;
   XSLoader::load Array::Heap2, $VERSION;
}

use base Exporter;

@EXPORT = qw(make_heap make_heap_lex make_heap_cmp push_heap push_heap_lex push_heap_cmp pop_heap pop_heap_lex pop_heap_cmp);

=item make_heap @heap                                   (\@)

Reorders the elements in the array so they form a heap, with the lowest
value "on top" of the heap (corresponding to the first array element).

=item make_heap_lex @heap                               (\@)

Just like C<make_heap>, but in string comparison order instead of numerical
comparison order.

=item make_heap_cmp { compare } @heap                   (&\@)

Just like C<make_heap>, but takes a custom comparison function.

=item push_heap @heap, $element, ...                    (\@@)

Adds the given element(s) to the heap.

=item push_heap_lex @heap, $element, ...                (\@@)

Just like C<push_heap>, but in string comparison order instead of numerical
comparison order.

=item push_heap_cmp { compare } @heap, $element, ...    (&\@@)

Just like C<push_heap>, but takes a custom comparison function.

=item pop_heap @heap                                    (\@)

Removes the topmost (lowest) heap element and repairs the heap.

=item pop_heap_lex @heap                                (\@)

Just like C<pop_heap>, but in string comparison order instead of numerical
comparison order.

=item pop_heap_cmp { compare } @heap                    (&\@)

Just like C<pop_heap>, but takes a custom comparison function.

=cut

1;

=back

=head2 COMPARISON FUNCTIONS

All the functions come in two flavours: one that uses the built-in
comparison function and one that uses a custom comparison function.

The built-in comparison function can either compare scalar numerical
values (string values for *_lex functions), or array refs. If the elements
to compare are array refs, the first element of the array is used for
comparison, i.e.

  1, 4, 6

will be sorted according to their numerical value,

  [1 => $obj1], [2 => $obj2], [3 => $obj3]

will sort according to the first element of the arrays, i.e. C<1,2,3>.

The custom comparison functions work similar to how C<sort> works: C<$a>
and C<$b> are set to the elements to be compared, and the result should be
either C<-1> if C<$a> is less than C<$b>, or C<< >= 0 >> otherwise.

The first example above corresponds to this comparison "function":

  { $a <=> $b }

And the second example corresponds to this:

  { $a->[0] <=> $b->[0] }

Unlike C<sort>, the default sort is numerical and it is not possible to
use normal subroutines.

=head1 BUGS

This module works not work with tied or magical arrays or array elements.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

