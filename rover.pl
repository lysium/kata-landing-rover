#!/usr/bin/env perl -w

use strict;

my $debug = 0;
# Usage: rover.pl X Y DIRECTION COMMAND_FILE PLANET_FILE
# Output:
#        DONE X Y DIRECTION
#  -or-  OBSTACLE X Y DIRECTION
#
# Internals:
# Coordinates for user:
#  - top, left is 0,0
#  - left <-> right is x-direction
#  - top <-> down is y-direction
#
# Coordinates in @planet:
#  - top, left is 0,0
#  - top <-> down is first dimension (file is read line-by-line)
#  - left <-> right is second dimension

my ($x, $y, $direction, $command_file, $planet_file) = @ARGV;
print "COMMANDS", join(" ", $x, $y, $direction, $command_file, $planet_file), "\n" if $debug;
open(COMMANDS, "<$command_file") or die;
open(PLANET, "<$planet_file") or die;

sub print_planet {
	my $planet = shift;
	for my $line (@$planet) {
		print join("  ", @$line), "\n";
	}
}

my @planet = <PLANET>;
close PLANET;
my $planet_height = scalar @planet;
my $planet_width = length($planet[0]) - 1; #-1 for newline
for my $line (@planet) {
	chomp $line;
	$line = [split //, $line];
	die "strange planet" if (scalar @$line != $planet_width);
}

print "$planet_height x $planet_width\n" if $debug;
print_planet(\@planet) if $debug;

sub move_forward {
	my ($x, $y, $direction) = @_;
	return move($x, $y, $direction, +1);
}

sub move_backward {
	my ($x, $y, $direction) = @_;
	return move($x, $y, $direction, -1);
}

sub move {
	my ($x, $y, $direction, $speed) = @_;
	if ($direction eq "E") {
		$x = $x + $speed;
	} elsif ($direction eq "S") {
		$y = $y + $speed;
	} elsif ($direction eq "W") {
		$x = $x - $speed;
	} elsif ($direction eq "N") {
		$y = $y - $speed;
	}
	return ($x, $y);
}

sub turn_left {
	my $direction = shift;
	my $new_direction = "X";
	if ($direction eq "E") {
		$new_direction = "N";
	} elsif ($direction eq "N") {
		$new_direction = "W";
	} elsif ($direction eq "W") {
		$new_direction = "S";
	} elsif ($direction eq "S") {
		$new_direction = "E";
	}
	return $new_direction;
}

sub turn_right {
	my $direction = shift;
	my $new_direction = "X";
	if ($direction eq "E") {
		$new_direction = "S";
	} elsif ($direction eq "N") {
		$new_direction = "E";
	} elsif ($direction eq "W") {
		$new_direction = "N";
	} elsif ($direction eq "S") {
		$new_direction = "W";
	}
	return $new_direction;
}

sub get_surface {
	my ($planet, $x, $y) = @_;
	# planet(y,x) as planet-file is read line-by-line
	my $surface = $planet->[$y]->[$x];
	return $surface;
}

sub wrap {
	my ($x, $max) = @_;
	return ($x + $max) % $max;
}

sub wrap_xy {
	my ($x, $y, $height, $width) = @_;
	my $new_x = wrap($x, $width);
	my $new_y = wrap($y, $height);
	return ($new_x, $new_y);
}

my $FREE_SURFACE = ".";
my $OBSTACLE = "x";

while (my $command = <COMMANDS>) {
	chomp $command;
	my ($new_x, $new_y, $new_direction) = ($x, $y, $direction);
	print $command, ": " if $debug;
	if ($command eq "MF") {
		($new_x, $new_y) = move_forward($x, $y, $direction);
	} elsif ($command eq "MB") {
		($new_x, $new_y) = move_backward($x, $y, $direction);
	} elsif ($command eq "TL") {
		$new_direction = turn_left($direction);
	} elsif ($command eq "TR") {
		$new_direction = turn_right($direction);
	}
	($new_x, $new_y) = wrap_xy($new_x, $new_y, $planet_height, $planet_width);
	print "$new_x, $new_y, $new_direction\n" if $debug;

	my $surface = get_surface(\@planet, $new_x, $new_y);
	print "SURFACE at $new_x, $new_y: $surface\n" if $debug;
	if ($surface eq $OBSTACLE) {
		print "OBSTACLE $x $y $direction\n";
		exit 1;
	} else {
		($x, $y, $direction) = ($new_x, $new_y, $new_direction);
	}
}
print "DONE $x $y $direction\n";
close COMMANDS;


