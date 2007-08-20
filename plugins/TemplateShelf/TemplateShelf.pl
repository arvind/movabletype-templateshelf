# Template Shelf, part of The Handyman - A plugin for Movable Type.
# Copyright (c) 2007 Arvind Satyanarayan.

package MT::Plugin::TemplateShelf;
use strict;

use MT 4.0;
use base 'MT::Plugin';
our $VERSION = '1.0';

my $plugin;
MT->add_plugin($plugin = __PACKAGE__->new({
	name            => "Template Shelf",
	version         => $VERSION,
	description     => "<__trans phrase=\"Adds a sidebar widget to the edit template screen that provides handy access to the other templates in the blog\">",
	author_name     => "Arvind Satyanarayan",
	author_link     => "http://www.movalog.com/",
}));

sub init_registry {
	my $plugin = shift;
	$plugin->registry({
		callbacks => {
			'MT::App::CMS::template_param.edit_template' => \&_edit_tmpl_param,
			'MT::App::CMS::template_source.edit_template' => \&_edit_tmpl
		}
	});
}

sub _edit_tmpl_param {
	my ($cb, $app, $param, $tmpl) = @_;

	my $filters = $app->list_filters('template');
    return '' if (ref($filters) ne 'ARRAY') || (! @$filters );
	$param->{list_filters} ||= $filters;

	my $parent_tmpl_type = $param->{type};
	
	my $terms = { };
	foreach my $filter (@$filters) {
		my $key = $filter->{key};
		$terms->{$key} ||= {};
		$filter->{handler}($terms->{$key});
		my $types = $terms->{$key} = $terms->{$key}->{type};
		$types = ref($types) eq 'ARRAY' ? "@$types" : $types;

		if($types =~ $parent_tmpl_type) {
			$param->{current_filter} = $key;
		}		
	}
	
	$param->{filter_terms} = $terms;
	
	my @tmpl_loop;	
	require MT::Template;
	my $iter = MT::Template->load_iter({ blog_id => $app->param('blog_id') }, { sort => 'name', direction => 'ascend' });
	while (my $tmpl = $iter->()) {
		push @tmpl_loop, {
			id => $tmpl->id,
			blog_id => $tmpl->blog_id,
			type => $tmpl->type,
			name => $tmpl->name
		}
	}
	$param->{tmpl_loop} = \@tmpl_loop;	
	$param->{is_dialog} = $app->param('dialog');
}

sub _edit_tmpl {
	my ($cb, $app, $tmpl) = @_;
	my $old = qq{<mt:include name="include/header.tmpl">};
	$old = quotemeta($old);
	
	require File::Spec;
	my $mini_tmpl = File::Spec->catdir($plugin->path,'tmpl','template_shelf.tmpl');
	my $new = qq{<mt:include name="$mini_tmpl">};
	$$tmpl =~ s/($old)/$new\n$1/;
	
	if($app->param('dialog')) {
		$new = <<HTML;
	<mt:setvar name="screen_type" value="dialog-screen dialog-4">
	<mt:include name="dialog/header.tmpl">
	<mt:if name="content_header">
	        <mt:var name="content_header">
	</mt:if>	
HTML
		$$tmpl =~ s/$old/$new/;
		
		$old = qq{<mt:include name="include/footer.tmpl">};
		$old = quotemeta($old);
		$new = qq{<mt:include name="dialog/footer.tmpl">};
		$$tmpl =~ s/$old/$new/;
		
		$$tmpl =~ s/setvartemplate/setvarblock/g;
	}
}
