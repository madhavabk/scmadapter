package PatchFile;

#   Author: Madhavarao Kulkarni(madhavabk@gmail.com)
#   This module is used to create file object that contains all meta data of the file.

#   Create a PatchFile object
sub new {
    my $class = shift;
    my $self = {
        filename => '',
        predname => "",
        pred_version => "",
        new_version => "",
        patch_flag => 0,
        url => "",
        patchPath => "",
    };
    bless($self, $class);
    return $self;
}

#   Getter / Setter functions
##############################
sub setName {
    my $self = shift;
    if ($#_ >= 0) {
        $self->{filename} = shift;
    } else {
        return $self->{filename};
    }
}

sub patchPath {
    my $self = shift;
    if ($#_ >= 0) {
        $self->{patchPath} = shift;
    } else {
        return $self->{patchPath};
    }
}

sub predName {
    my $self = shift;
    if ($#_ >= 0) {
        $self->{predname} = shift;
    } else {
        return $self->{predname};
    }

}

sub revision {
    my $self = shift;
    if ($#_ >= 0) {
        $self->{filename} = shift;
    } else {
        return $self->{filename};
    }

}

sub process
{
    my $self = shift;
    my @values = split(" ", $self->{filename});
    $self->{filename} = $values[1];
    if($values[2] =~ m/working/) {
        $self->{patch_flag} = 1;
    } else {
        $self->{new_version} = $values[3];
    }
    @values = split(" ", $self->{predname});
    $self->{predname} = $values[1];
    $self->{pred_version} = $values[3];
    #remove the ) pattern.
    chomp($self->{pred_version});
    $self->{pred_version} =~ s/\)//;
}

sub copy_files
{
    my $self = shift;
    my $env = shift;
    if($self->{scm_type} == "SVN" ) {
        #create modified file now.
        if( $self->{filename} =~ qr/\// )
        {
            my @dirs = split("/", $self->{filename});
            pop @dirs; # Remove the last element which is file name.
            my $path = join('/', @dirs);
            system("mkdir -p $env->{OUTPUT_PATH}/$path");
        }
        `touch $env->{OUTPUT_PATH}/$self->{filename}`;
        if( $self->{predname} =~ qr/\// )
        {
            my @dirs = split("/", $self->{predname});
            pop @dirs; # Remove the last element which is file name.
            my $path = join('/', @dirs);
            system("mkdir -p $env->{OUTPUT_PATH}/$path");
        }
        my $userid = "";
        my $password = "";
        $self->{url} = "";
        my $svn_cat_opt = "--trust-server-cert --non-interactive --no-auth-cache --username $userid --password \'$password\'";
        `$env->{SCM_COMMANDS}->{SVN} cat -r $self->{pred_version} $svn_cat_opt $self->{url}$self->{predname} > $env->{OUTPUT_PATH}/$self->{filename}`;
    }

}

sub patchIt {
    my($self, $env) = @_;
    my $patchCmd = $env->{PATCH_CMD};
    $patchCmd = $patchCmd . " " . $env->{OUTPUT_PATH} . "/" . $self->{filename} . " -b " . " < " . $self->{patchPath};
    my $out = `$patchCmd`;
    if( $out > 0 ) {
        print "Sorry an error occurred while patching $self->{filename}\n";
    }
}

1;
