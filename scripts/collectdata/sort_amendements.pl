#!/usr/bin/perl

$textjson = shift;
$outputtype = shift;

open JSON, "$textjson";
while(<JSON>) {
    next unless (/"article"/);
    if (/"titre": "([^"]+)"/) {
	$titre = $1;
	/order": (\d+),/;
        $articles{lc($titre)} = $1 * 10;
    }
}
close JSON;

sub clean_subject {
    $subj = shift;
    $subj = lc($subj);
    $subj =~ s/È/è/g;
    $subj =~ s/premier/1er/i;
    $subj =~ s/unique/1er/i;
    $subj =~ s/\s*\(((avant|apr).*)\)/ \1/;
    $subj =~ s/\(.*//;
    $subj =~ s/\s*$//;
    $subj =~ s/^\s*//;
    $subj =~ s/^(\d)/article \1/;
    $subj =~ s/articles/article/i;
    $subj =~ s/art(\.|icle|\s)*(\d+)/article \2/i;
    $subj =~ s/^(apr\S+s|avant)\s*/article additionnel \1 /;
    $subj =~ s/(apr\S+s|avant)\s+Article/\1 l'article/i;
    $subj =~ s/(\d+e?r? )([a-z]{1,2})$/\1\U\2/i;
    $subj =~ s/(\d+e?r? \S+ )([a-z]+)$/\1\U\2/i;
    $subj =~ s/ annexe.*//i;
    $subj =~ s/ rapport.*//i;
    $subj =~ s/Article 1$/article 1er/i;
    return $subj;
}
sub solveorder {
    $art = shift;
    if ($art =~ /^motion/i) {
        return 0;
    } elsif ($art =~ /^(pro(jet|position)|texte)/i) {
        return 1;
    } elsif ($art =~ /^titre$/i || $art =~ /^intitul/i) {
        return -5;
    }
    $order = -1;
    if ($art =~ /article (\d.*)/i) {
	next unless ($articles{lc($1)});
        $order = $articles{lc($1)};
        if ($art =~ /avant/i) {
            $order--;
        } elsif ($art =~ /apr\S+s/i) {
            $order++;
        }
    }
    return $order;
}

while(<STDIN>) {
    if ($outputtype eq 'csv'){
        @csv = split /;/;
        $sujet = clean_subject($csv[6]);
        $order = solveorder($sujet);
        $order = 'ordre article' if ($sujet eq "sujet");
        s/;$csv[6];/;$order;$sujet;/;
    } elsif($outputtype eq 'xml') {
	@partialxml = ();
	foreach $l (split/<amendement>/) {
	    if ($l =~ /<sujet>([^<]+)<\/sujet>/) {
		$sujet = clean_subject($1);
		$order = solveorder($sujet);
		$l =~ s/<sujet>[^<]*<\/sujet>/<ordre_article>$order<\/ordre_article><sujet>$sujet<\/sujet>/;
	    }
	    push @partialxml, $l;
	}
	$_ = join('<amendement>', @partialxml);
    } elsif($outputtype eq 'json') {
	@partialjson = ();
	foreach $l (split(/},/)) {
	    if ($l =~ /"sujet":"([^"]+)"/) {
		$sujet = clean_subject($1);
		$order = solveorder($sujet);
		$l =~ s/"sujet":"[^"]*",/"sujet":"$sujet","ordre_article":$order,/;
	    }
	    push @partialjson, $l;
	}
	$_ = join('},', @partialjson);
    }
    print;
}