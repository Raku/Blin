use Blin::Module;
use Whateverable::Config;

use Whateverable::Bisection;
use Whateverable::Builds;
use Whateverable::Config;
use Whateverable::Output;
use Whateverable::Running;

unit module Blin::Processing;

# Testing and Bisection

# Keep in mind that here we are bisecting `fail`s only.
# Normally bisectable can bisect things that were not working
# in the past but now succeed. Here we don't do that. In fact,
# we don't even test the module on the old revision if it
# succeeds on the new revision.

#| Value descriptions:
#| * Unknown – Not tested yet
#| * OK – Succeeds on end point
#| * Fail – Succeeds on start point but fails on end point (regression)
#| * Flapper – Fails intermittently on end point
#| * AlwaysFail – Fails on both end point and start point
#| * InstallableButUntested – Same as OK but with --/test
#| * MissingDependency – Depends on a Perl 6 module that does not exist
#| * CyclicDependency – Depends on itself or has a cycle somewhere in the dependency graph
#| * BisectFailure – Same as Fail but bisection failed
#| * ZefFailure – Something something
#| * UnhandledException – Should not happen, a bug in Blin
enum Status is export <
     Unknown OK Fail Flapper AlwaysFail
     InstallableButUntested
     MissingDependency CyclicDependency
     BisectFailure ZefFailure
     UnhandledException
>;

# TODO move this to Whateverable ?
my @annoying-revisions = |<
92c504ba5589a2e82a4513afb8329f8010d0b170
3cc3574437e6c9ab4b34cfdd3dd02237802520d9
350a4bd46ef60736e694b65358ca065cce168ded
f731c81466c5640f1f639732bf33a3fcbeb69d86
a24c37b3b44ed45f45f0cc2b507a87719cac310b
512dbe6e5458290fbeeeb8d12dacb85acbb8fc69
2ba1cff822ede6ce9b301ae3d6a951166466ef2a
e31a480be1eb13721b02c94dac975541aa0e2c59
11c9942dd4293ccdb2f772abfc944355ecf36b3b
04304d2e93ce2e9fa0870697944758552f8e9bf0
1b912311c77c7cead527e264cc1536f68f1205ac
99af79f3ed96afa68a1e624f0aafba590c1d0c58
6ed65efbd95f3e7097a1d7b4119aa33b3b764de1
510c342538d88394723792fc83966184b7f155f6
de98129322489bc57c1997b8b620363977c28e8c
232454ab56197b695d298dd0c6fb5add6451842a
626b657f9044177ff54060a9d9e510cbe283a723
61937cbeac7adc98594f06c4be763204067b10f9
602ca5bd3d8b77a7a28ef17f3bee3ef5f84291bd
499b2192790f5d2a66fdc6bd3513c7155f245229
c2b66c144c368f4d98a542d4de3c553e85febbe5
5fe0140cfd4dbacd3a696aaefedc8ad30e6a6269
7865d36c29635707339a7aa4d38c18913d69a775
34845aa3321a26a1c44f8f8c6ba6d1d3542a7b53
8d9b31287c4bf6ac7756e2814e1066f6c1f4d722
4420ed423499e483c9966911dd518c6263504a0e
4b1827c499020c9f90e7e4c919abb45a3a27e540
1225d00aa0e244a6f5316f9da82c6052e8600345
ad16e5367127299c035f42cc1253c6f944c91b02
46faa86d540799f1cb5e320b751c972618d158e3
9c68c550d161a587cd80caa4342a714a0e6ba394
ce63be30e718c6f7aa0f2ca8c5a226de25d38dd4
e49c4ece56dd1b0c883a3b6f42141e92648413bb
e2cb4d07bb1a40690257b9070d4a6ccef6ca2fb8
61e6cbf1ddc239330a62ca666c6ee28812cf4352
cb206b104318446dd69eba02e9557573c9413557
cfd66de6a16c3d226a725889dee7363a05aa720c
2558ffa9be0224e1c719ffc82d4d342180057028
1a95d05e24971d1abc0772ecba1f02a2f825fb3f
45a30db8e25c68e61dc832c3f4ef89da153b9c64
a18b897e190007cdb7eb85ad1331fef24497b7a8
569ef2dac8a499efe804c02f4ae8808055a27ac2
01f959fd88efca00a8da96ece8d6fcd9b1809221
13caa77a15959051a85dc9cdd5676df05e0900d5
8a999990d3f2d410ffb35b0f921a86e89f4dde52
58f577a1b136150f1e852fa892dead9328307b24
77c462b5718000fe07eed0ff344edfea3f2eaff8
692d0e398213f5ba4255554b915482013f3ad02b
93dbf87d031ed93d1d86caa65ed9c761fa60211b
7e21a777f62c1680e84bef334988cd72f5ad546f
4817b93d32decf5c60d8a8f1b58e607d81e594c0
0d77f3223837941ecd0a4d06a2ffcdf11910859d
4b6b68d9d62488b2a9ebe4f0e47cfd7e11f14296
a7a8850694a80915a6c5814ce308f2f524555a90
750befd5e64bc7521df916056c9d9e66eac9c2a3
6f7aec5bd8f49fa9cc6940497b35467158ac078a
77630e543834dced4b5535cc9bed1cff04d1b216
945fdd6ee90f5cf7259b015575d8f476d9e377e6
a22bf543ef51fa5c7af92d38644b50a673ccc2fa
4fa3fa91a2372274ba8c63d50700873327677a87
245102d205367da174a21a2d1daddc12739ed18d
f38633fcc0903c523053760cf335349ee4f9d4df
bf9f3540fee7fbe2ff71e331c0229ce6155484c0
78f3578ceb677745dc59f56d4b2dd25ecb71f97e
25c83ceada560892c77e5aaf49f20475a2a3609a
2de8a7e10ba3a8f5b9e58b6b8ce2d47ba8b62c99
e02ddce83f86663f12d88a5d2c30b6782df2af5e
305d9da0a0c279d3d29c9ddf4ef3e005565b241d
1477b6c1c2b08c3d6e22b8acfcc14cb070c13bc2
74c2ab117e4e9c46a74a5ca902f9d40cc3ede54b
2ce329cada339bc614b719df50a7572ce7d7e63c
4accb64148ee49580cb15caa276909a20997491b
0a4250236055d18ee6591252788ce6c91e50461e
3b453c575de14efd3abfa4f49c82a059ddccc3cd
8c693bf8ec0f4b8c9cec90eb2934251e236c9676
5c9e00d587f969554f65e8640f09e4bc61a3c6dc
bbeb40d556ac8747b444e1d05ef06ee73b6b0568
20f0df8f7251486a5ea0a160cc88459937f4aa12
9e3b197ac9b91d74040ab8704c52e52663a6f23f
a30766b39b22297b4bd1d192875daf817da680ca
294edfaefb23ff1d5eecb7945238ec1e08934427
9463906b98112ad69183916af95982f3be96d7b8
640491d60c0e159f78d358116056684fc448d860
b998bfe576612e54d6a887508d4981e86ae0f1d0
e34f66e3a27cfa7f77d9a1de9502aec636c44ec1
a628e1c608c6230ac37af05075116bb95b909156
95991afd3d25ce9a27cdf49c001be479cf6c3ff2
ee213cb451e9b7cc698cb13d7ed873a989b1a6c1
d9c0a92af16016482b3d73e193231e64f5bb2bb9
c65ad93129a6f933f55ba71c0f0f3ee3d5f1ed33
1feebcbdfeb56b84ec2ed9d68f6ec4eb76a4abbf
8a46b614c4d31b62ae7aa98c8f2bdafd227aff51
34f1b310b24cc9b9001291e63005d9f742147726
8909cff195694af2bc8966a62f8d1920bc6fc4c3
40348ae4913fc3cc186041676290a8786c178168
994940a824c95835cc59ccbd3dca5d2e22d20b84
44ef8fc0c98f55d48701ac6958b638602ffa29e6
f434e3406569f309995c4980090d039405cbb50d
580a232e2fa6898e7db7ed4a97d1df8bd55241ec
37ff7c6edfc71782c94b4149c18807f8659d26c2
2053dded74926537eccb9d490a35edfd3c1a0cd0
f6d0bcbbb2a8be56bd842c96cba39af49680ed53
0e91822bdf2fa02fe79d2e6ed279d38cbdbfc671
71f0d3bb8fcfc79eb9f9089f69d38c590b7ad39e
4bb16b5a8f3d3ba32b14b7a744b995084d3ce07d
e1fc8255a99e48ba4fa523ef5a39865a3bf8aa80
13950b7f070ea7f475161e47368c1da6b670b820
ab4207fae1e3e6ddcc88bbfc474dd2ba24949e1f
c85028b2808c8519e9883ec376243acee883d38e
cc5d957c69b570d4c9e124664b66feb87c6d23fc
f386b98e087f4974060460b50e98eadaf5b7cdad
fdfdbdb111678863d1b331780408d438fdfe3375
1f9fcad23c439465ab324d5c1ba7fb3fa2510b27
c5383a1cf3685016e324b03e63da020ba18cb30f
7f874551b5ee3298e29ee31ec862ec9d12bb7693
9cdd8b33967bee88f320fe2a6113ed8accbdc18e
4ad1ac2d98552807fa9cf3a7a907f7319685da21
3dfbddf850281ab6f1ee4ef82f878968b2147934
0087c77e7f1d9157c295425ead2bab6e8af3addf
3a333be14fa4ca4f3e3a26df2367810ccca90ac7
40096821aea53ccff827f4c211613da5a26b52a8
b0135ef4c6451d30fba5a8e0ba0dccb6dfb25dea
cfb70b30350dc29da64c69cdce7838bc3b63bcc3
104059c2a6c380e9a44fc58e6fde23d8e7546a83
8c888adf9254667f0264cb43db5aa664a880e9e5
cbde083fa2ebb65fa2d8e8a794b82260db326aef
85a481c7d8b780dba0ba7c30a37465083f441f7a
07dacc257016ceb81012a9ed3b6eccfbc8c1c1b7
8f6a1058e74bdd11de793042eca5a1cf0b4cc9a2
7e335826d40958b55e1c4d0c0b479b3bc2bde898
5d412528ada7d976c7fd804e0958aa9651f4ccd5
81390d18182537741b7bd11c1e6318236a8e58ba
ccac70c9c984d22f36326695f94d0077d643c1ff
cf4feb472aca9d9bb03815fb4aa5f532f1c99500
503650a730548894834c1b83f5c5c86c12d9a42d
f910dc86ed610c1cb54d3406590e1fa2b697115b
7a95dd8c8ae4aefd25c598c91477be6d4d112d0e
bdbc7735fb8890efad2acae20e77e91025f326b0
fb90c9b8e174ec11ef260b7b25635765ca756f2d
baf1d0231874ab39459f77b4e04ed619b39e5caf
2a64d2f2f26f3618dff989ee2dd0377294a868be
683728bb583d3a9c25a961de7959e8ce53539540
2d1fb3fd1e079faac81a60d7fe12548a13df3a8b
12e408edbed3cd419fc292fab7143172c97b5033
7b2790cf42850e0f9247be5de8a4222ca0d22410
7a54dce6110360f0c2cb0fbfca303c1143cec81a
4b8e1a0d7470a219b6e75533a48becbac5bc5586
>,
# TODO I can't believe that I pasted the
# whole thing right here. Someone please
# do something about it. These shas came
# from `git log` of the js branch merge.
|<
a2023397b0a53cdd6fb165bf67ea867e8e7b8e31
1978fd1d7266f4a0a155d15c92d8e8850450a089
2e0d8b362df11b90c2cc810cfed38c7a18bcc716
2a84ee0bc3389b967df803cba2ea9b5edf74e725
955748066e0049a2ee579a23dbf882d5996be151
977b04aab9aa59185ac13e3c7f7fe130f2c23bfd
0e10dff33c2199c06a6a7a6fa49a82e10d191b05
aa14457ba3ae99631bdf39d73a85bb7ba4bce897
456b08e35eeebaa9255aade221ea8a96f32192aa
fb4b636c47e3cad90e67942541dde9ed50377d77
df77eb6a44e0253d756b274d1318af6804bd79ec
c176289ffe75342c156f2390061cfbb4b639e5c3
0cb7e5f2875f2fb014b9813c0c87dd71c97a4e05
68974ea50588a0815be1d3eb01701edbd9ff7a7b
786c51143ecdb232e3a1632716a7899367095b9e
cd62aee0081ea0303718cb1c7ed5f13101413b46
dc8663a1ce9b4124f42f26fae7f40eaae818937a
ab85d0a9d7d213c960025ea82eeed6fd85dfa638
2b99afeb5cacc38b6b4ad9170f2dd6b3a774aa42
32756b20cf19f80f311ca0405bfaf6e9e138874f
f000dff36b0f382fb19b3f1a60cd0171650d80ed
8e818ed6ae8aa799c4ec2429293b49981cb2262a
a2ddab894811d3614bd671a2fceb731aa3dd134d
d7fb541e77f632136083972afb447c0451f16572
4051b6f8d238f5bcd0836bcc907a978ea549a524
71a6c9854f2f3b6905e563c8686484b7da72ac99
89e72806a82284bba16089c9f9aebe2db4302608
2e8bb95e817258ab1c62ce5f02b74f5cb47d9a28
d7ec8c9826b55bed2a93bb55182d8b25f0b7f8ef
2c91f3c7d710959e381b13578406e4be45b64f95
136a5ccc8d7adc429c8db5bfaba6d05072605e5e
0b8270a3b21614bfdb485d44fb9b68bf355d9269
39610732a77d0af5b360bde82310abe2437720e2
dd722c3872bd990d294858c40043fd630a2f2ec1
d03ae346d0b9bc33381c142a79fe7961f36e49d2
ef072b66486399a1194e4fa12b1bd0ef24b06482
cf9a9305271319a2f47be9db281533567c3fcbc9
71c942832b294fd9f4349d04d7d3f6c30d572bfb
18c5ee84d0c6d0bac3076280e124acd41a7073b1
a7eb035d80fb15f080ff4d674986eefb85a87755
06069f260539006f0dfcf706119a6c15df970d27
631468e79f2873c760f41eb51ddae867efe9c499
bf1d35f8d2a1727379e68db65a46b777889c3f5f
311e2a93bb457d7d74c791442128687f5da7223c
3ee37925508fd13687f6cd517567c6f8c49ba143
7175b29254ae243fcf7065742e49d4c52b858d84
7da860b4fbfd2cfe656d1fa5315d9fd8575d48b1
c076d1d2d6cf51c6d0dc55fe0be2a345a9b0b566
8d5da1da027206e8eabc9706ae1ed71c283bfef4
146cd286ca0ad2721447d5f069f02d44d2ac5932
fe975582cff517ef03fcafadf605e4bdf281801b
45e72d05b47a64213059422fb0379530cd99c4b8
5fc48bb51427542bd79f2d030336c8179fde86f9
32d4840eaa82b5decef43b122c8335d598477b35
ebea4fc8527e380cdf282c3e19f9eddad9870fce
ea8322df6d9719eace1886ebc7191b75d4f7037c
aef86400db406d4748ee3a9fc7a9870e231bd38d
1c87d9ff24b2e2bda92805463d63bc5e8ca4abc6
f9b591f036f6b636d066c969da9bd5ca56b80bfc
75ce005c5704a508eb6ed812453ac6ba7c2cd62f
463a13dc895cf6dfeb850b281d703003df147679
a55eaa62048db56450672525d44f74ee570b6783
105268eab6c109089e89ae339c6d8b09762042ac
c820894ecd591c9ac9e7fbe85916d256d7ba5b2f
ab7cf8edde8b67b9b4356faeaa1967e0bb753450
79e6c424e5f362702380009654e181de857d54c0
2474adb8f699498b6d83a70b91edefc47fd49784
c1d4a2d353defd22989a944981b36532bafd3134
c90ad2a00e06f091543918b5c265dfc851fb5b87
2da32b62793ec8fce4c507886f7686007aa0088b
9ad1cf2a65933f1ee4878d84bdf0970ce9d3aedf
2204a1ad3c16b3695dbe33bb8df9b2b1255c1a43
b64da2964cb1d8e38c001e1d3ca886363326ba0b
1211440c642d6486afccc42b2b376649b3956f23
10d1e1796b820b7c350c2d1c1554da6c761d48fe
917cfaf1274c3fca4e4e0a2e6781ea909d595f77
38960c61595cf51cda5c3e85350df0a8d2e50534
2a8b0ee4709484c4dae8c91e8ae2baeeb94edea2
edec947490e397d02070842dbac60fb5de449870
73abad03eb6f522a6cc42e9747ac9518cad7aea2
f38be9296371b420b8beafd6971aa97d72f041dc
7bf6c6f4818cfbd034e6d279d551f2b10a29384a
4ab552355943fb4d80a5aebea2b28b97b11f6118
55697fa4fcdcd796abfe57cd8f7a72d1f53dd2be
19dd95990001018e1d255ecc366dac0f625fb8bb
b52586b1981c84cbd500ca103f27d1c9a0b91d00
3de47eb04c76ceb3ea0d36bd6057ac1d65395af8
1b3b82d98198e6050f58927b0bb999cf20c86d11
ee7cd7070c2d37a9cab7ecfdfeda4fdef21c186c
2da8192d38f63bda709f9a72a9da2e3963435090
b956e062a73834dd80f246d0e2f5377e405b3883
6e37be5f751aee0a703f4d39aeee29078ea97d23
2ce954d3a731c46c88de90d46fefb8dd0e1a6348
91dd06ea9a2aafddd3db03618cca06640fea9c83
b48c4481bc33c1f9388ef011b01a5d1a641497ec
35ed92bc99307f48de720edc96a091c58b0aad82
82846b624ef3ec78ac848720fb85067947613420
7baae044def074b673fcecc0b75389b6e9cbf834
ab99511246c9fa8006b9d36d85639bfc222d0296
c2725e70917a87afe254d216fc4f78915ade2530
409b3d4de1534eb676536abb2beb5b5d674c6ee2
c848ac590f3282b85ca12c3d1dd9e3626f7aed20
fa77d97952a107b9680b2a258b0c4299873002b6
4a865106c4393dac7b9c0cb094a0fe323d9d1a3e
ee7671649c1972f7ba6a1ea61a9758a5671c2558
9eeaa6f267068dc5566b0cbd71c0ee55adddc294
5c1b5e6eab2721588ba515c5a4c7a47b79483f2c
9bbab7333074ad15082d5729f593131496c47954
3cc214bd344d33148a0a0102137097f5e4b511f5
424d19083afc3a1c39c0b21454eb2f14188863f8
936b5a5f233eb7b14ce8d268dfe9e690101ab243
2aabee80a5bcb7065c797da0b1abeb50b12f83aa
fadfeb2098669d6a7cf13d497d7876820cfca322
d9e12bc437181b330d058132c09fe7556d824077
639dbbd388f5cb341bb15149bf98d64d6f285c1a
0e88cd187f40811500e0ad0be0a6ecc0ef64bc68
63cae004f3aa7e89bdc94cf3db29830702ad693b
6caf58cb418f444c21afc6ff0d2c731c093c8fa6
fad44ff7f581dd1eb4bbb02513e19c4104920395
8905159d89d9ca316a33902da5128077d9a64fa3
825ffb154a0717e8745cca1015e169e480547f64
f94049c42125a7ac25f0d0ce3dcd957534305409
ef1c8f3ea435c81a39df8de525273fc5ac0387ad
4e47144e6122d7f820545d013eb33a69059e80cb
a80a5ae5f84a5edbb7861590d2296ed6fbbdd5db
1a6fa6e4de8922c0638ae05a0a96110a1909b29d
df853a0cd751b48e87c2dd04a7770a899e2fccda
0ec08b60de7bdef2a0205f00431dca0ac6af0cfb
1ef5a970ad6166ebc1a7baf49d9a753724d75ab8
bccb2c88e9ececb7b7bed2872a4ff51026fc8e21
79abb4e9deb4cfb86eaa44d05ee8118f55924320
bf346147007c1c54c2ca42236c71583d0829c68f
130a92b95ddd3ae6760718eaa9bad5c81d552048
f16c03d9af46ec2c85bea6d6e9b275bd5bc1dada
cf606ff24573b16decda58a0a5ef65d2d5d1d8d9
293a3bd48e2a0f1e476bb6cff08c8b5ce18bc2f2
01d8c166b1abb16fb76fae8750af7d1075ee6bef
1a79284ab2eee69a67521a338ae18850a62c662c
b175ba8eeed58b8ac83af158a0618bb79f4d3f8d
478a43a26015bcd267b167239f98ecf1322c4c9e
a9a72473fccc3e9d6b773378d545dc20cbcd51b6
81edd34dec01d05e1d6536cde9e8098ba14fa0bf
d5435e5d528b54d5f003926ad038723759fe774f
a309d67941188ac94e073198e77059dc5b83cb7a
5ada814d33f14ae3e26a9b3e44dcf99041defff9
a813f251ae7500c04afa583b2c01ffce23132997
2709d73632d8873bdc071526159c66c905748bb0
>;

#| Test some $module on some commit ($full-commit-hash)
sub test-module($full-commit-hash, $module,
                :$install=False,
                :$zef-path!, :$zef-config-path, :$timeout!,
                :@always-unpacked, :$testable=True) is export {

    if $full-commit-hash eq @annoying-revisions.any {
        return %(output => ‘This revision is known to divert bisection into the wrong direction’,
                 exit-code => -1, signal => -1, time => -1,)
    }

    build-exists $full-commit-hash;
    my $install-path = $module.install-path;
    mkdir $install-path;

    my @deps = gather $module.deps: True;
    @deps .= unique;

    sub run-it($path) { # basically runs zef
        my $binary-path = $path.IO.add: ‘bin/perl6’;
        my %tweaked-env = %*ENV;
        %tweaked-env<PATH> = join ‘:’, $binary-path.parent, (%tweaked-env<PATH> // Empty);
        %tweaked-env<PERL6LIB> = $zef-path.add: ‘/lib’;
        %tweaked-env<PERL6LIB> = join ‘,’, %tweaked-env<PERL6LIB>, # XXX looks fragile
                                   |@deps.map: { ‘inst#’ ~ .install-path.IO.absolute };
        %tweaked-env<ALL_TESTING>     = 1;
        %tweaked-env<NETWORK_TESTING> = 1;
        %tweaked-env<ONLINE_TESTING>  = 1;

        if $binary-path.IO !~~ :e {
            return %(output => ‘Commit exists, but a perl6 executable could not be built for it’,
                     exit-code => -1, signal => -1, time => -1,)
        }

        my $result;
        if $module.test-script { # fake module
            $result = get-output $binary-path,
                      ‘--’,
                      $module.test-script,
                      :stdin(‘’), :$timeout, ENV => %tweaked-env, :!chomp;
        } else { # normal module
            $result = get-output $binary-path,
                      ‘--’,
                      $zef-path.add(‘/bin/zef’),
                      “--config-path=$zef-config-path”,
                      <--verbose --force-build --force-install>,
                      ($testable ?? ‘--force-test’ !! ‘--/test’),
                      <--/depends --/test-depends --/build-depends>,
                      ‘install’,
                      ($install ?? Empty !! ‘--dry’),
                      “--to=inst#$install-path”, $module.name,
                      :stdin(‘’), :$timeout, ENV => %tweaked-env, :!chomp;
        }
        # XXX ↓ this workaround looks stupid
        $result<exit-code> = 1 if $result<output>.contains: ‘[FAIL]:’;
        $result
    }

    if $full-commit-hash eq @always-unpacked.any {
        return run-it run-smth-build-path $full-commit-hash
    } else {
        return run-smth $full-commit-hash, &run-it
    }
}

#| Perform full processing of a single module.
#| This includes testing it on two revisions, deflapping,
#| and bisecting if needed.
sub process-module(Module $module,
                   :$deflap!,
                   :$start-point-full!, :$end-point-full!,
                   :$zef-path!, :$zef-config-path, :$timeout!,
                   :@always-unpacked,
                   :$testable=True,
                  ) is export {

    my $perl6lib = $module.depends.keys.map(*.install-path).join: ‘,’;

    my &alright = -> $result {
        if $result<signal> ≠ 0 {
            # Huh, that means Zef itself segfaulted.
            return $module.done.keep: ZefFailure
        }
        $result<exit-code> == 0
    }

    my $OK = $testable ?? OK !! InstallableButUntested;

    note “🥞🥞🥞 Testing $module.name() (new)”; # (new revision, end point)
    my $new-result = test-module   $end-point-full, $module,
                                 :$zef-path, :$zef-config-path, :$timeout,
                                 :@always-unpacked, :$testable,
                                 install => $module.needed;
    $module.output-new = $new-result<output>;
    spurt $module.install-path.IO.add(‘log-new’), $module.output-new;
    return $module.done.keep: $OK if alright $new-result; # don't even test the old one

    note “🥞🥞🥞 Testing $module.name() (old)”; # (old revision, start point)
    my $old-result = test-module $start-point-full, $module,
                                 :$zef-path, :$zef-config-path, :$timeout,
                                 :@always-unpacked, :$testable;
    $module.output-old = $old-result<output>;
    spurt $module.install-path.IO.add(‘log-old’), $module.output-old;

    return $module.done.keep: AlwaysFail unless alright $old-result;

    note “🥞🥞🥞 Testing $module.name() for flappiness”;
    for ^$deflap {
        # Be careful when touching this piece of code. If you break
        # it, all regressions will appear as flappers
        if not alright test-module $start-point-full, $module,
                                   :$zef-path, :$zef-config-path, :$timeout,
                                   :@always-unpacked, :$testable {
            return $module.done.keep: Flapper
        }
        # TODO also test end point too and see if we can confirm that
        # it's not a flapper, if it is a flapping regression then
        # deflap on every bisect step?
    }

    note “🥞🥞🥞 Bisecting $module.name()”;
    use File::Temp;
    use File::Directory::Tree;
    my $repo-cwd = tempdir :!unlink;
    LEAVE rmtree $_ with $repo-cwd;
    run :out(Nil), :err(Nil), <git clone>, $CONFIG<rakudo>, $repo-cwd;

    my $bisect-start = get-output cwd => $repo-cwd, <git bisect start>;
    my $bisect-old   = get-output cwd => $repo-cwd, <git bisect old>, $start-point-full;
    if $bisect-start<exit-code> ≠ 0 or $bisect-old<exit-code> ≠ 0 {
        return $module.done.keep: BisectFailure
    }
    my $init-result = get-output cwd => $repo-cwd, <git bisect new>, $end-point-full;

    my &runner = -> :$current-commit, *%_ { test-module $current-commit, $module,
                                            :$zef-path, :$zef-config-path, :$timeout,
                                            :@always-unpacked, :$testable
                                          };
    my $bisect-result = run-bisect &runner, :$repo-cwd,
                                   old-exit-code => $old-result<exit-code>;

    $module.bisected = $bisect-result<first-new-commit>;
    spurt $module.install-path.IO.add(‘bisect-log’), $bisect-result<log>;
    $module.done.keep: Fail
}
