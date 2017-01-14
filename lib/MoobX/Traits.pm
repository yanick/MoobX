package MoobX::Traits;

package MoobX::Trait::Observable;

use Moose::Role;
use MoobX;
use Moose::Util;

Moose::Util::meta_attribute_alias('Observable');

use experimental 'signatures';

after initialize_instance_slot => sub($attr_self,$,$instance,$) {

    $instance->meta->add_before_method_modifier( $attr_self->get_read_method, sub($self,@) {
        push @MoobX::DEPENDENCIES, $attr_self if $MoobX::WATCHING;
    }) if $attr_self->has_read_method;

    $instance->meta->add_after_method_modifier( $attr_self->get_write_method, sub {
        my( $self, $value ) = @_;
        MoobX::observable_ref($value) if ref $value;
        MoobX::observable_modified( $attr_self );
    }) if $attr_self->has_write_method;

};

package Moose::Meta::Attribute::Custom::Trait::Observer;

use Moose::Role;
use MoobX::Observer;

use experimental 'signatures';

before _process_options => sub {
    my( $self, $name, $args) = @_;

    my $gen = $args->{default};

    $args->{default} = sub { 
        my @args = @_;
        MoobX::Observer->new(
            generator => sub { $gen->(@args) },
            autorun => !$args->{lazy},
        ) 
    };
    
};


1;
