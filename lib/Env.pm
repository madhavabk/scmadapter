#!perl

package Env;
#   Author: Madhavarao Kulkarni(madhavabk@gmail.com)
#   This module will be used to create environemnt object that can be passed between moduels.

sub new {
    my $class = shift;
    my $self = {
        SCM_COMMANDS => { SVN => "/usr/bin/svn",
                          CLEARTOOL => "/usr/atria/bin/cleartool",
                          GIT => "/usr/bin/git",
                          CVS => "/usr/bin/cvs",
                        },
        OUTPUT_PATH => "../output",
        PATCH_CMD => "/usr/bin/patch",
    };
    bless ($self, $class);
    return $self;
}

1;
