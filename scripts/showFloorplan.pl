#!/usr/bin/perl -w
# Copyright (c) 2015, University of Kaiserslautern
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
#    contributors may be used to endorse or promote products derived from
#    this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
# TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER
# OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# Authors: Matthias Jung

use strict;
use warnings;
use SVG;

my $file   = shift || die("Please specify fpl file!");
my $height = shift || die("Please specify height!");
my $width  = shift || die("Please specify width!");
my $zoom   = shift || die("Please specify the zoom factor!");


# Extract Filename:
unless($file =~ /(.+)\.flp/ || $file =~ /(.+)\.mlt/)
{
    die("Please provide a fpl/mlt filetype");
}
my $outfile = $1;

open(FH, $file);

my $height_zoom = $height/$zoom;
my $svg = SVG->new(width => $width/$zoom, height => $height/$zoom);

my $name ="";
my $x = 0;
my $y = 0;
my $w = 0;
my $h = 0;

my $rect_begin = 0;

while(<FH>)
{
    my $line = $_;
    

    if($line =~ /^(.+)\s*:\s*\n$/)
    {
        $name = $1;
    }
    elsif($line =~ /position\s*(\d+),\s*(\d+)\s*;/)
    {
        $x = $1;
        $y = $2;
    }
    elsif($line =~ /dimension\s*(\d+),\s*(\d+)\s*;/)
    {
        $w = $1;
        $h = $2;

        $y = $height - $y -$h;

        $x = $x / $zoom;
        $y = $y / $zoom;
        $w = $w / $zoom;
        $h = $h / $zoom;

        $svg->rectangle(
            x => $x,
            y => $y,
            width => $w,
            height => $h,
            style => {
                'fill' => 'rgb(128, 128, 128)',
                'stroke' => 'black',
                'stroke-width' => 1,
                'stroke-opacity' => 1,
                'fill-opacity' => 0.5,
            },
        );

        my $textx = $x + $w/2;
        my $texty = $y + $h/2;

        $svg->text(
            #id=>$name,
            x => $textx,
            y => $texty,
            "text-anchor"=>"middle",
            "alignment-baseline"=>"middle",
        )->cdata($name);
    }
    elsif($line =~ /rectangle\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)\s*;/)
    {
        $rect_begin++;

        my $x1 = $1;
        my $y1 = $2;
        my $x2 = $3;
        my $y2 = $4;

        $x = $x1;
        $y = $y1;
        $w = $x2-$x1;
        $h = $y2-$y1;

        $y = $height - $y -$h;

        $x = $x / $zoom;
        $y = $y / $zoom;
        $w = $w / $zoom;
        $h = $h / $zoom;

        $svg->rectangle(
            x => $x,
            y => $y,
            width => $w,
            height => $h,
            style => {
                'fill' => 'rgb(128, 128, 128)',
                'stroke' => 'black',
                'stroke-width' => 1,
                'stroke-opacity' => 0.5,
                'fill-opacity' => 0.5,
            },
        );
    }
    else
    {
        if($rect_begin != 0)
        {
            my $textx = $x + $w/2;
            my $texty = $y + $h/2;

            $svg->text(
                #    id=>"rect_".$name,
                x => $textx,
                y => $texty,
                "text-anchor"=>"middle",
                "alignment-baseline"=>"middle",
            )->cdata($name);
            $rect_begin = 0;
        }
    }
}



# convert into svg
open my $out, '>', "$outfile.svg" or die;
print $out $svg->xmlify;

# convert to pdf
system("inkscape $outfile.svg --export-pdf=$outfile.pdf");

