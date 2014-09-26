# Movable Type (r) (C) 2001-2014 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package MT::DataAPI::Resource::Blog::v2;

use strict;
use warnings;

use MT::Entry;
use MT::DataAPI::Resource;

sub updatable_fields {
    [
        # v1 fields
        qw(
            name
            description
            url
            archiveUrl
            ),

        # v2 fields

        # Create Blog screen
        qw(
            themeId
            sitePath
            serverOffset
            language
            ),

        # General Settings screen
        qw(
            fileExtension
            archiveTypePreferred
            publishEmptyArchive
            includeSystem
            includeCache
            useRevision
            maxRevisionsEntry
            maxRevisionsTemplate
            ),

        # Compose Settings screen
        qw(
            listOnIndex
            daysOrPosts
            sortOrderPosts
            wordsInExcerpt
            basenameLimit
            statusDefault
            convertParas
            allowCommentsDefault
            allowPingsDefault
            contentCss
            nwcSmartReplace
            ),

        # Feedback Settings screen
        qw(
            junkFolderExpiry
            junkScoreThreshold
            nofollowUrls
            followAuthLinks
            allowComments
            moderateComments
            allowCommentHtml
            sanitizeSpec
            emailNewComments
            sortOrderComments
            autolinkUrls
            convertParasComments
            useCommentConfirmation
            allowPings
            moderatePings
            emailNewPings
            autodiscoverLinks
            internalAutodiscovery
            ),

        # Registration Settings screen
        qw(
            allowCommenterRegist
            newCreatedUserRole
            allowUnregComments
            requireCommentEmail
            commenterAuthenticators
            ),

        # Web Services Settings screen
        qw(
            pingGoogle
            pingWeblogs
            pingOthers
            ),

        # template tags
        qw(
            dateLanguage
            ),
    ];
}

sub fields {
    [   {   name        => 'updatable',
            type        => 'MT::DataAPI::Resource::DataType::Boolean',
            from_object => sub {
                my ($obj) = @_;
                return if !$obj->id;

                my $app = MT->instance;
                my $user = $app->user or return;

                return $user->permissions( $obj->id )
                    ->can_do('edit_blog_config');
            },
        },

        # Create Blog screen
        {   name      => 'themeId',
            alias     => 'theme_id',
            condition => \&_can_view,
        },
        {   name      => 'sitePath',
            alias     => 'site_path',
            condition => \&_can_view,
        },
        {   name      => 'archivePath',
            alias     => 'archive_path',
            condition => \&_can_view,
        },
        qw(
            serverOffset
            language
            ),

        # General Settings screen
        {   name      => 'fileExtension',
            alias     => 'file_extension',
            condition => \&_can_view,
        },
        {   name      => 'archiveTypePreferred',
            alias     => 'archive_type_preferred',
            condition => \&_can_view,
        },
        {   name        => 'publishEmptyArchive',
            alias       => 'publish_empty_archive',
            type        => 'MT::DataAPI::Resource::DataType::Boolean',
            from_object => sub { $_[0]->publish_empty_archive },
            condition   => \&_can_view,
        },
        {   name        => 'includeSystem',
            alias       => 'include_system',
            from_object => sub { $_[0]->include_system },
            condition   => \&_can_view,
        },
        {   name        => 'includeCache',
            alias       => 'include_cache',
            type        => 'MT::DataAPI::Resource::DataType::Boolean',
            from_object => sub { $_[0]->include_cache },
            condition   => \&_can_view,
        },
        {   name      => 'useRevision',
            alias     => 'use_revision',
            type      => 'MT::DataAPI::Resource::DataType::Boolean',
            condition => \&_can_view,
        },
        {   name        => 'maxRevisionsEntry',
            alias       => 'max_revisions_entry',
            from_object => sub { $_[0]->max_revisions_entry },
            condition   => \&_can_view,
        },
        {   name        => 'maxRevisionsTemplate',
            alias       => 'max_revisions_template',
            from_object => sub { $_[0]->max_revisions_template },
            condition   => \&_can_view,
        },

        # Compose Settings screen
        {   name        => 'listOnIndex',
            from_object => sub {
                my ($obj) = @_;
                return $obj->entries_on_index || $obj->days_on_index || 0;
            },
            condition => \&_can_view_cfg_screens,
        },
        {   name        => 'daysOrPosts',
            from_object => sub {
                my ($obj) = @_;
                my $type = $obj->entries_on_index ? 'posts' : 'days';
                return $type;
            },
            condition => \&_can_view_cfg_screens,
        },
        {   name      => 'sortOrderPosts',
            alias     => 'sort_order_posts',
            condition => \&_can_view_cfg_screens,
        },
        {   name      => 'wordsInExcerpt',
            alias     => 'words_in_excerpt',
            condition => \&_can_view_cfg_screens,
        },

        # dateLanguaage is defined in template tags.
        {   name      => 'basenameLimit',
            alias     => 'basename_limit',
            condition => \&_can_view_cfg_screens,
        },
        {   name        => 'statusDefault',
            alias       => 'status_default',
            from_object => sub {
                my ($obj) = @_;
                MT::Entry::status_text( $obj->status_default );
            },
            to_object => sub {
                my ($hash) = @_;
                MT::Entry::status_int( $hash->{statusDefault} );
            },
            condition => \&_can_view_cfg_screens,
        },
        {   name      => 'convertParas',
            alias     => 'convert_paras',
            condition => \&_can_view_cfg_screens,
        },
        {   name      => 'allowCommentsDefault',
            alias     => 'allow_comments_default',
            type      => 'MT::DataAPI::Resource::DataType::Boolean',
            condition => \&_can_view_cfg_screens,
        },
        {   name      => 'allowPingsDefault',
            alias     => 'allow_pings_default',
            type      => 'MT::DataAPI::Resource::DataType::Boolean',
            condition => \&_can_view_cfg_screens,
        },
        {   name      => 'contentCss',
            alias     => 'content_css',
            condition => \&_can_view_cfg_screens,
        },
        {   name        => 'nwcSmartReplace',
            alias       => 'nwc_smart_replace',
            from_object => sub {
                my ($obj) = @_;
                $obj->nwc_smart_replace;
            },
            condition => \&_can_view_cfg_screens,
        },

        # Feedback Settings screen
        {   name      => 'junkFolderExpiry',
            alias     => 'junk_folder_expiry',
            condition => \&_can_view_cfg_screens,
        },
        {   name      => 'junkScoreThreshold',
            alias     => 'junk_score_threshold',
            condition => \&_can_view_cfg_screens,
        },
        {   name        => 'nofollowUrls',
            alias       => 'nofollow_urls',
            type        => 'MT::DataAPI::Resource::DataType::Boolean',
            from_object => sub {
                my ($obj) = @_;
                $obj->nofollow_urls;
            },
            condition => \&_can_view_cfg_screens,
        },
        {   name        => 'followAuthLinks',
            alias       => 'follow_auth_links',
            type        => 'MT::DataAPI::Resource::DataType::Boolean',
            from_object => sub {
                my ($obj) = @_;
                $obj->follow_auth_links;
            },
            condition => \&_can_view_cfg_screens,
        },
        {   name        => 'allowComments',
            type        => 'MT::DataAPI::Resource::DataType::Boolean',
            from_object => sub {
                my ($obj) = @_;
                return $obj->allow_reg_comments || $obj->allow_unreg_comments;
            },
            type_to_object => sub {
                my ( $hashes, $objs ) = @_;
                for ( my $i = 0; $i < scalar @$objs; $i++ ) {
                    if ( $hashes->[$i]->{allowComments} ) {
                        $objs->[$i]->allow_reg_comments(1);
                    }
                    else {
                        $objs->[$i]->allow_unreg_comments(0);
                        $objs->[$i]->allow_reg_comments(0);
                    }
                }
            },
            condition => \&_can_view_cfg_screens,
        },
        {   name      => 'moderateComments',
            alias     => 'moderate_unreg_comments',
            condition => \&_can_view_cfg_screens,
        },
        {   name      => 'allowCommentHtml',
            alias     => 'allow_comment_html',
            type      => 'MT::DataAPI::Resource::DataType::Boolean',
            condition => \&_can_view_cfg_screens,
        },
        {   name      => 'sanitizeSpec',
            alias     => 'sanitize_spec',
            condition => \&_can_view_cfg_screens,
        },
        {   name      => 'emailNewComments',
            alias     => 'email_new_comments',
            condition => \&_can_view_cfg_screens,
        },
        {   name      => 'sortOrderComments',
            alias     => 'sort_order_comments',
            condition => \&_can_view_cfg_screens,
        },
        {   name      => 'autolinkUrls',
            alias     => 'autolink_urls',
            type      => 'MT::DataAPI::Resource::DataType::Boolean',
            condition => \&_can_view_cfg_screens,
        },
        {   name      => 'convertParasComments',
            alias     => 'convert_params_comments',
            condition => \&_can_view_cfg_screens,
        },
        {   name      => 'useCommentConfirmation',
            alias     => 'use_comment_confirmation',
            type      => 'MT::DataAPI::Resource::DataType::Boolean',
            condition => \&_can_view_cfg_screens,
        },
        {   name      => 'allowPings',
            alias     => 'allow_pings',
            type      => 'MT::DataAPI::Resource::DataType::Boolean',
            condition => \&_can_view_cfg_screens,
        },
        {   name      => 'moderatePings',
            alias     => 'moderate_pings',
            type      => 'MT::DataAPI::Resource::DataType::Boolean',
            condition => \&_can_view_cfg_screens,
        },
        {   name      => 'emailNewPings',
            alias     => 'email_new_pings',
            condition => \&_can_view_cfg_screens,
        },
        {   name      => 'autodiscoverLinks',
            alias     => 'autodiscover_links',
            type      => 'MT::DataAPI::Resource::DataType::Boolean',
            condition => \&_can_view_cfg_screens,
        },
        {   name      => 'internalAutodiscovery',
            alias     => 'internal_autodiscovery',
            type      => 'MT::DataAPI::Resource::DataType::Boolean',
            condition => \&_can_view_cfg_screens,
        },

        # Registration Settings screen
        {   name      => 'allowCommenterRegist',
            alias     => 'allow_commenter_regist',
            type      => 'MT::DataAPI::Resource::DataType::Boolean',
            condition => \&_can_view_cfg_screens,
        },
        {   name        => 'newCreatedUserRole',
            from_object => sub {
                my ($obj) = @_;
                my $app = MT->instance;
                my @def = split ',', $app->config('DefaultAssignments');
                my @roles;
                while ( my $r_id = shift @def ) {
                    my $b_id = shift @def;
                    next unless $b_id eq $obj->id;
                    my $role = $app->model('role')->load($r_id)
                        or next;
                    push @roles, $role;
                }
                return MT::DataAPI::Resource->from_object( \@roles );
            },
            condition => \&_can_view_cfg_screens,
        },
        {   name      => 'allowUnregComments',
            alias     => 'allow_ungreg_comments',
            type      => 'MT::DataAPI::Resource::DataType::Boolean',
            condition => \&_can_view_cfg_screens,
        },
        {   name      => 'requireCommentEmail',
            alias     => 'require_comment_email',
            type      => 'MT::DataAPI::Resource::DataType::Boolean',
            condition => \&_can_view_cfg_screens,
        },
        {   name        => 'commenterAuthenticators',
            alias       => 'commenter_authenticators',
            from_object => sub {
                my ($obj) = @_;
                my $auths = $obj->commenter_authenticators or return [];
                return [ split ',', $auths ];
            },
            to_object => sub {
                my ($hash) = @_;
                if ( ref $hash->{commenterAuthenticators} eq 'ARRAY' ) {
                    return join( ',', @{ $hash->{commenterAuthenticators} } );
                }
                else {
                    return '';
                }
            },
            condition => \&_can_view_cfg_screens,
        },

        # Web Services Settings screen
        {   name      => 'pingGoogle',
            alias     => 'ping_google',
            type      => 'MT::DataAPI::Resource::DataType::Boolean',
            condition => \&_can_view_cfg_screens,
        },
        {   name      => 'pingWeblogs',
            alias     => 'ping_weblogs',
            type      => 'MT::DataAPI::Resource::DataType::Boolean',
            condition => \&_can_view_cfg_screens,
        },
        {   name     => 'pingOthers',
            alias    => 'ping_others',
            codition => \&_can_view_cfg_screens,
        },

        # template tags
        {   name        => 'ccLicenseImage',
            from_object => sub {
                my ($obj) = @_;
                my $cc = $obj->cc_license or return '';
                my ( $code, $license, $image_url )
                    = $cc =~ /(\S+) (\S+) (\S+)/;
                return $image_url if $image_url;
                "http://creativecommons.org/images/public/"
                    . ( $cc eq 'pd' ? 'norights' : 'somerights' );
            },
        },
        qw(
            ccLicenseUrl
            dateLanguage
            ),
        {   name        => 'host',
            from_object => sub {
                my ($obj) = @_;
                my $host = $obj->site_url;
                return '' unless defined $host;
                if ( $host =~ m!^https?://([^/:]+)(:\d+)?/?! ) {
                    return $1 . ( $2 || '' );
                }
                else {
                    return '';
                }
            },
        },
        {   name        => 'relativeUrl',
            from_object => sub {
                my ($obj) = @_;
                my $host = $obj->site_url;
                return '' unless defined $host;
                if ( $host =~ m{^https?://[^/]+(/.*)$} ) {
                    return $1;
                }
                else {
                    return '';
                }
            },
        },
        {   name        => 'timezone',
            from_object => sub {
                my ($obj)               = @_;
                my $so                  = $obj->server_offset;
                my $partial_hour_offset = 60 * abs( $so - int($so) );
                return sprintf( "%s%02d:%02d",
                    $so < 0 ? '-' : '+',
                    abs($so),, $partial_hour_offset );
            },
        },
    ];
}

sub _can_view {
    my $app  = MT->instance;
    my $user = $app->user;

    require MT::CMS::Blog;
    if (!(  $user && ( $user->is_superuser
                || $app->can_do('access_to_blog_config_screen')
                || MT::CMS::Blog::can_view( undef, $app, 1 ) )
        )
        )
    {
        return;
    }

    return 1;
}

sub _can_view_cfg_screens {
    my $app = MT->instance;
    return $app->can_do('edit_config');
}

1;

__END__

=head1 NAME

MT::DataAPI::Resource::Blog::v2 - Movable Type class for resources definitions of the MT::Blog.

=head1 AUTHOR & COPYRIGHT

Please see the I<MT> manpage for author, copyright, and license information.

=cut
