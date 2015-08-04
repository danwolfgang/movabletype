# Movable Type (r) (C) 2001-2015 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package MT::Asset::oEmbed;

use strict;
use base qw( MT::Asset );

use Symbol;
use URI::Escape;
use POSIX qw( floor );

__PACKAGE__->install_properties(
    {   class_type    => 'oembed',
        provider_type => 'oembed',
        column_defs   => {
            'file_url'                  => 'vclob meta',
            'type'                      => 'vchar meta',
            'version'                   => 'vchar meta',
            'title'                     => 'vchar meta',
            'author_name'               => 'vchar meta',
            'author_url'                => 'vclob meta',
            'provider_name'             => 'vchar meta',
            'provider_url'              => 'vclob meta',
            'cache_age'                 => 'integer meta',
            'provider_thumbnail_url'    => 'vclob meta',
            'provider_thumbnail_width'  => 'integer meta',
            'provider_thumbnail_height' => 'integer meta',
        },
        child_of => [ 'MT::Blog', 'MT::Website', ],
    }
);

sub install_properties {
    my $class = shift;
    my ($props) = @_;

    my $super_props = $class->SUPER::properties();
    if ($super_props) {
        if ( $super_props->{provider_type} ) {

            # copy reference of class_to_provider/provider_to_class hashes
            $props->{__class_to_provider}
                = $super_props->{__class_to_provider};
            $props->{__provider_to_class}
                = $super_props->{__provider_to_class};
        }
    }

    if ( my $type = $props->{provider_type} ) {
        $props->{__class_to_provider}{$class} = $type;
        $props->{__provider_to_class}{$type}  = $class;
    }

    $class->SUPER::install_properties($props);

    return $props;
}

sub can_handle {
    my ( $pkg, $url ) = @_;

    my $domains = $pkg->domains || [];
    foreach my $domain (@$domains) {
        return 1 if ( $url =~ /$domain/ );
    }
    return 0;
}

sub get_embed {
    my $asset = shift;
    my ($url) = @_;

    $url = $url || $asset->url();

    return undef unless $url;

    $asset->url($url) unless $asset->url();

    $url = Encode::encode_utf8($url) unless Encode::is_utf8($url);
    my $param = uri_escape_utf8($url);

    my $ua = MT->new_ua();
    $ua->agent( 'MovableType/' . MT->version_id );
    $ua->ssl_opts( verify_hostname => 0 );
    my $endpoint = $asset->properties->{endpoint};
    my $res      = $ua->get( $endpoint . '?url=' . $param . '&format=json' );

    if ( $res->is_success ) {
        require JSON;
        my $json = JSON::from_json( $res->content() );
        for my $k (
            qw( type version author_name author_url provider_name provider_url cache_age )
            )
        {
            my $item = delete $json->{$k};
            $asset->$k($item) if $item;
        }
        for my $k (qw( thumbnail_url thumbnail_width thumbnail_height )) {
            my $item = delete $json->{$k};
            if ($item) {
                my $method = "provider_$k";
                $asset->$method($item) if $item;
            }
        }
        my $title = delete $json->{title};
        $asset->label($title);
        my $file_url = $json->{url} || $asset->provider_thumbnail_url;
        $asset->file_url($file_url);
        $asset->file_path($file_url);
        my $file_name
            = $file_url =~ /(.*)\/(.*)/
            ? $2
            : $file_url;
        $asset->file_name($file_name);
        my $start    = rindex( $file_url, "." ) + 1;
        my $end      = length($file_url);
        my $file_ext = substr( $file_url, $start, $end - $start );
        $asset->file_ext($file_ext);

        foreach my $k ( keys(%$json) ) {
            $asset->$k( $json->{$k} ) if $json->{$k};
        }
    }
    else {
        return $asset->error(
            MT->translate( "Error embed: [_1]", $res->content ) );
    }
    return $asset;
}

sub domains { [] }

sub thumbnail_path {
    my $asset = shift;
    my (%param) = @_;

    $asset->provider_thumbnail_url();
}

sub thumbnail_file {
    my $asset = shift;
    my (%param) = @_;
    my $fmgr;
    my $blog = $param{Blog} || $asset->blog;

    require MT::FileMgr;
    $fmgr ||= $blog ? $blog->file_mgr : MT::FileMgr->new('Local');
    return undef unless $fmgr;

    my $file_path = $asset->file_path;
    return undef unless $file_path;

    require MT::Util;
    my $asset_cache_path = $asset->_make_cache_path( $param{Path} );
    my ( $i_h, $i_w ) = ( $asset->image_height, $asset->image_width );
    return undef unless $i_h && $i_w;

    # Pretend the image is already square, for calculation purposes.
    my $auto_size = 1;
    if ( $param{Square} ) {
        require MT::Image;
        my %square
            = MT::Image->inscribe_square( Width => $i_w, Height => $i_h );
        ( $i_h, $i_w ) = @square{qw( Size Size )};
        if ( $param{Width} && !$param{Height} ) {
            $param{Height} = $param{Width};
        }
        elsif ( !$param{Width} && $param{Height} ) {
            $param{Width} = $param{Height};
        }
        $auto_size = 0;
    }
    if ( my $scale = $param{Scale} ) {
        $param{Width}  = int( ( $i_w * $scale ) / 100 );
        $param{Height} = int( ( $i_h * $scale ) / 100 );
        $auto_size     = 0;
    }
    if ( !exists $param{Width} && !exists $param{Height} ) {
        $param{Width}  = $i_w;
        $param{Height} = $i_h;
        $auto_size     = 0;
    }

    # find the longest dimension of the image:
    my ( $n_h, $n_w, $scaled )
        = _get_dimension( $i_h, $i_w, $param{Height}, $param{Width} );
    if ( $auto_size && $scaled eq 'h' ) {
        delete $param{Width} if exists $param{Width};
    }
    elsif ( $auto_size && $scaled eq 'w' ) {
        delete $param{Height} if exists $param{Height};
    }

    my $file = $asset->thumbnail_filename(%param) or return;
    my $thumbnail = File::Spec->catfile( $asset_cache_path, $file );

    # thumbnail file exists and is dated on or later than source image
    my $orig_mod_time = $asset->get_original_mod_time();
    if (   $fmgr->exists($thumbnail)
        && $orig_mod_time
        && ( $fmgr->file_mod_time($thumbnail) >= $orig_mod_time ) )
    {
        my $already_exists = 1;
        if ( $asset->image_width != $asset->image_height ) {
            require MT::Image;
            my ( $t_w, $t_h )
                = MT::Image->get_image_info( Filename => $thumbnail );
            if (   ( $param{Square} && $t_h != $t_w )
                || ( !$param{Square} && $t_h == $t_w ) )
            {
                $already_exists = 0;
            }
        }
        return ( $thumbnail, $n_w, $n_h ) if $already_exists;
    }

    # stale or non-existent thumbnail. let's create one!
    return undef unless $fmgr->can_write($asset_cache_path);

    # download original image
    my $orig_img = $asset->_download_image_data();
    return undef unless $orig_img && $fmgr->file_size($orig_img);

    my $data;
    if (   ( $n_w == $i_w )
        && ( $n_h == $i_h )
        && !$param{Square}
        && !$param{Type} )
    {
        $data = $fmgr->get_data( $orig_img, 'upload' );
    }
    else {

        # create a thumbnail for this file
        require MT::Image;
        my $img = new MT::Image( Filename => $orig_img )
            or return $asset->error( MT::Image->errstr );

        # Really make the image square, so our scale calculation works out.
        if ( $param{Square} ) {
            ($data) = $img->make_square()
                or return $asset->error(
                MT->translate( "Error cropping image: [_1]", $img->errstr ) );
        }

        ($data) = $img->scale( Height => $n_h, Width => $n_w )
            or return $asset->error(
            MT->translate( "Error scaling image: [_1]", $img->errstr ) );

        if ( my $type = $param{Type} ) {
            ($data) = $img->convert( Type => $type )
                or return $asset->error(
                MT->translate( "Error converting image: [_1]", $img->errstr )
                );
        }
    }
    $fmgr->put_data( $data, $thumbnail, 'upload' )
        or return $asset->error(
        MT->translate( "Error creating thumbnail file: [_1]", $fmgr->errstr )
        );
    $fmgr->delete($orig_img);
    return ( $thumbnail, $n_w, $n_h );
}

sub _get_dimension {
    my ( $i_h, $i_w, $h, $w ) = @_;

    my ( $n_h, $n_w ) = ( $i_h, $i_w );
    my $scale = '';
    if ( $h && !$w ) {
        $scale = 'h';
    }
    elsif ( $w && !$h ) {
        $scale = 'w';
    }
    else {
        if ( $i_h > $i_w ) {

            # scale, if necessary, by height
            if ( $i_h > $h ) {
                $scale = 'h';
            }
            elsif ( $i_w > $w ) {
                $scale = 'w';
            }
        }
        else {

            # scale, if necessary, by width
            if ( $i_w > $w ) {
                $scale = 'w';
            }
            elsif ( $i_h > $h ) {
                $scale = 'h';
            }
        }
    }
    if ( $scale eq 'h' ) {

        # scale by height
        $n_h = $h;
        $n_w = floor( ( $i_w * $h / $i_h ) + 0.5 );
    }
    elsif ( $scale eq 'w' ) {

        # scale by width
        $n_w = $w;
        $n_h = floor( ( $i_h * $w / $i_w ) + 0.5 );
    }
    $n_h = 1 unless $n_h;
    $n_w = 1 unless $n_w;

    return ( $n_h, $n_w, $scale );
}

sub thumbnail_filename {
    my $asset   = shift;
    my (%param) = @_;
    my $file    = $asset->file_name or return;

    require MT::Util;
    my $format = $param{Format} || MT->translate('%f-thumb-%wx%h-%i%x');
    my $width  = $param{Width}  || 'auto';
    my $height = $param{Height} || 'auto';
    $file =~ s/\.\w+$//;
    my $base = File::Basename::basename($file);
    my $id   = $asset->id;
    my $ext  = lc( $param{Type} || '' ) || $asset->file_ext || '';
    $ext = '.' . $ext;
    $format =~ s/%w/$width/g;
    $format =~ s/%h/$height/g;
    $format =~ s/%f/$base/g;
    $format =~ s/%i/$id/g;
    $format =~ s/%x/$ext/g;
    return $format;
}

sub _download_image_data {
    my $asset = shift;
    my $url
        = $asset->type eq 'photo'
        ? $asset->file_url
        : $asset->provider_thumbnail_url;

    return unless $url;

    my $ua = MT->new_ua(
        {   agent    => 'MovableType/' . MT->version_id,
            max_size => 1_000_000,
        }
    );
    $ua->ssl_opts( verify_hostname => 0 );

    my $req = HTTP::Request->new( 'GET', $url );
    my $res = $ua->request($req);

    if ( $res->is_success ) {
        require File::Temp;
        my $tmp_dir = MT->config('TempDir');
        my ( $tmp_fh, $tmp_file ) = File::Temp::tempfile( DIR => $tmp_dir );

        binmode $tmp_fh;
        print $tmp_fh $res->content;
        close $tmp_fh;

        return $tmp_file;
    }
    else {
        return $asset->error(
            MT->translate( "Error download: [_1]", $res->content ) );
    }
}

sub get_original_mod_time {
    undef;
}

1;