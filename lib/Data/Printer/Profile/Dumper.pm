package Data::Printer::Profile::Dumper;
use strict;
use warnings;

sub profile {
    return {
        show_tainted => 0,
        show_unicode => 0,
        show_lvalue  => 0,
        print_escapes => 0,
        scalar_quotes => q('),
        escape_chars => 'none',
        string_max => 0,
        unicode_charnames => 0,
        array_max => 0,
        index => 0,
        hash_max => 0,
        hash_separator => ' => ',
        align_hash => 0,
        sort_keys => 0,
        quote_keys => 1,
        name => '$VAR1->',
        return_value => 'dump',
        output => 'stderr',
        indent => 10,
        show_readonly => 0,
        show_tied => 0,
        show_dualvar => 'off',
        show_weak => 0,
        show_refcount => 0,
        show_memsize => 0,
        separator => ',',
        end_separator => 0,
        caller_info => 0,
        colored => 0,
        class_method => undef,
        # Data::Printer doesn't provide a way to directly
        # decorate filters, so we do it ourselves:
        filters => [
            {
                '-class'  => \&_data_dumper_class_filter,
                'SCALAR'  => \&_data_dumper_scalar_filter,
                'LVALUE'  => \&_data_dumper_lvalue_filter,
                'HASH'    => \&_data_dumper_hash_filter,
                'ARRAY'   => \&_data_dumper_array_filter,
                'CODE'    => \&_data_dumper_code_filter,
                'FORMAT'  => \&_data_dumper_format_filter,
                'GLOB'    => \&_data_dumper_glob_filter,
                #'REF'     => ,
                'Regexp'  => \&_data_dumper_regexp_filter,
                #'VSTRING' => ,
            },
        ],
    };
}

sub _data_dumper_regexp_filter {
    my ($re, $ddp) = @_;
    my $v = "$re";
    my $mod = "";
    if ($v =~ /^\(\?\^?([msixpadlun-]*):([\x00-\xFF]*)\)\z/) {
      $mod = $1;
      $v = $2;
      $mod =~ s/-.*//;
    }
    $v =~ s{/}{\\/}g;
    return _output_wrapper($ddp, "qr/$v/$mod");
}

sub _data_dumper_glob_filter {
    my ($glob, $ddp) = @_;
    my $ret = "$$glob";
    $ret =~ s|\A\*main:|\*:|;
    $ret =~ s|\A\*|\\*{'|;
    $ret .= '\'}';
    return _output_wrapper($ddp, $ret);
}

sub _data_dumper_lvalue_filter {
    my (undef, $ddp) = @_;
    Data::Printer::Common::_warn('cannot handle ref type 10');
    return _output_wrapper($ddp, '');
}

sub _data_dumper_scalar_filter {
    my ($scalar, $ddp) = @_;
    my $ret = Data::Printer::Filter::SCALAR::parse(@_);
    return _output_wrapper($ddp, $ret);
}

sub _data_dumper_format_filter {
    my (undef, $ddp) = @_;
    Data::Printer::Common::_warn('cannot handle ref type 14');
    return _output_wrapper($ddp, '');
}

sub _data_dumper_code_filter {
    my (undef, $ddp) = @_;
    return _output_wrapper($ddp, 'sub { "DUMMY" }');
}

sub _data_dumper_array_filter {
    my ($hashref, $ddp) = @_;
    my $ret = Data::Printer::Filter::ARRAY::parse(@_);
    return _output_wrapper($ddp, $ret);
}

sub _data_dumper_hash_filter {
    my ($hashref, $ddp) = @_;
    my $ret = Data::Printer::Filter::HASH::parse(@_);
    return _output_wrapper($ddp, $ret);
}

sub _data_dumper_class_filter {
    my ($obj, $ddp) = @_;
    require Scalar::Util;
    my $reftype = Scalar::Util::reftype($obj);
    $reftype = 'Regexp' if $reftype eq 'REGEXP';
    my ($parse_prefix, $parse_suffix) = ('', '');
    if ($reftype eq 'SCALAR') {
        $parse_prefix = 'do{\(my $o = ';
        $parse_suffix = ')}';
    }
    $ddp->indent;
    my $ret = 'bless( ' . $parse_prefix . $ddp->parse_as($reftype, $obj) . $parse_suffix . q|, '| . ref($obj) . q|' )|;
    $ddp->outdent;

    return _output_wrapper($ddp, $ret);
}

sub _output_wrapper {
    my ($ddp, $output) = @_;
    if ($ddp->current_depth == 0) {
        $output = '$VAR1 = ' . $output . ';';
    }
    return $output;
}

1;
__END__

=head1 NAME

Data::Printer::Profile::Dumper - use DDP like Data::Dumper

=head1 SYNOPSIS

While loading Data::Printer:

    use DDP profile => 'Dumper';

While asking for a print:

    p $var, profile => 'Dumper';

or in your C<.dataprinter> file:

    profile = Dumper

=head1 DESCRIPTION

This profile tries to simulate Data::Dumper's output as closely as possible,
using Data::Printer, even skipping types unsupported by Data::Dumper like lvalues
and formats.

It's not guaranteed to be 100% accurate, but hopefully it's close enough :)

=head2 Notable Diferences from Data::Dumper

It's important to notice that this profile tries to emulate
Data::Dumper's I<output>, NOT its behaviour. As such, some things are
still happening in a much DDP-ish way.

* no $VAR2, ...
* return value
* prototypes
* still called 'p' (say alias = 'Dumper' if you want)


=head1 SEE ALSO

L<Data::Printer>
L<Data::Dumper>
