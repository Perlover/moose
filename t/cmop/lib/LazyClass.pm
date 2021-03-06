
package # hide the package from PAUSE
    LazyClass::Attribute;

use strict;
use warnings;

use Carp 'confess';

our $VERSION = '0.05';

use parent 'Class::MOP::Attribute';

sub initialize_instance_slot {
    my ($self, $meta_instance, $instance, $params) = @_;

    # if the attr has an init_arg, use that, otherwise,
    # use the attributes name itself as the init_arg
    my $init_arg = $self->init_arg();

    if ( exists $params->{$init_arg} ) {
        my $val = $params->{$init_arg};
        $meta_instance->set_slot_value($instance, $self->name, $val);
    }
}

sub accessor_metaclass { 'LazyClass::Method::Accessor' }

package # hide the package from PAUSE
    LazyClass::Method::Accessor;

use strict;
use warnings;

use Carp 'confess';

our $VERSION = '0.01';

use parent 'Class::MOP::Method::Accessor';

sub _generate_accessor_method {
    my $attr = (shift)->associated_attribute;

    my $attr_name = $attr->name;
    my $meta_instance = $attr->associated_class->get_meta_instance;

    sub {
        if (scalar(@_) == 2) {
            $meta_instance->set_slot_value($_[0], $attr_name, $_[1]);
        }
        else {
            unless ( $meta_instance->is_slot_initialized($_[0], $attr_name) ) {
                my $value = $attr->has_default ? $attr->default($_[0]) : undef;
                $meta_instance->set_slot_value($_[0], $attr_name, $value);
            }

            $meta_instance->get_slot_value($_[0], $attr_name);
        }
    };
}

sub _generate_reader_method {
    my $attr = (shift)->associated_attribute;

    my $attr_name = $attr->name;
    my $meta_instance = $attr->associated_class->get_meta_instance;

    sub {
        confess "Cannot assign a value to a read-only accessor" if @_ > 1;

        unless ( $meta_instance->is_slot_initialized($_[0], $attr_name) ) {
            my $value = $attr->has_default ? $attr->default($_[0]) : undef;
            $meta_instance->set_slot_value($_[0], $attr_name, $value);
        }

        $meta_instance->get_slot_value($_[0], $attr_name);
    };
}

package # hide the package from PAUSE
    LazyClass::Instance;

use strict;
use warnings;

our $VERSION = '0.01';

use parent 'Class::MOP::Instance';

sub initialize_all_slots {}

1;

__END__

=pod

=head1 NAME

LazyClass - An example metaclass with lazy initialization

=head1 SYNOPSIS

  package BinaryTree;

  use metaclass (
      ':attribute_metaclass' => 'LazyClass::Attribute',
      ':instance_metaclass'  => 'LazyClass::Instance',
  );

  BinaryTree->meta->add_attribute('node' => (
      accessor => 'node',
      init_arg => ':node'
  ));

  BinaryTree->meta->add_attribute('left' => (
      reader  => 'left',
      default => sub { BinaryTree->new() }
  ));

  BinaryTree->meta->add_attribute('right' => (
      reader  => 'right',
      default => sub { BinaryTree->new() }
  ));

  sub new  {
      my $class = shift;
      $class->meta->new_object(@_);
  }

  # ... later in code

  my $btree = BinaryTree->new();
  # ... $btree is an empty hash, no keys are initialized yet

=head1 DESCRIPTION

This is an example metclass in which all attributes are created
lazily. This means that no entries are made in the instance HASH
until the last possible moment.

The example above of a binary tree is a good use for such a
metaclass because it allows the class to be space efficient
without complicating the programing of it. This would also be
ideal for a class which has a large amount of attributes,
several of which are optional.

=head1 AUTHORS

Stevan Little E<lt>stevan@iinteractive.comE<gt>

Yuval Kogman E<lt>nothingmuch@woobling.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2008 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
