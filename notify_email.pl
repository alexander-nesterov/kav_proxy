#!/usr/bin/perl

#for the test
#./c-icap-client -v -s av/reqmod -f test_files.zip -d 9

#for Ubuntu/Debian
#apt-get install libmime-lite-perl

use strict;
use warnings;
use MIME::Lite;
use MIME::Base64;

use constant SMTP_SERVER 	=> 'your_smtp_server';
use constant EMAIL_FROM 	=> 'kav-gate@example.ru';
use constant EMAIL_TO 		=> 'test1@example.ru;test2@example.ru';
use constant DEBUG 		=> 0; #0 - False, 1 - True

my %MESSAGE;
$MESSAGE{0}{'text'}{'ru'}   = 'Список вирусов, которыми заражен объект';
$MESSAGE{0}{'text'}{'en'}   = 'List of viruses that an object is infected with';
$MESSAGE{1}{'text'}{'ru'}   = 'Список объектов, содержащих код, похожий на код известного вируса';
$MESSAGE{1}{'text'}{'en'}   = 'List of objects containing code that resembles a known virus';
$MESSAGE{2}{'text'}{'ru'}   = 'Список объектов, подозреваемых на заражение неизвестным вирусом';
$MESSAGE{2}{'text'}{'en'}   = 'List of objects suspected of infection with an unknown virus';
$MESSAGE{3}{'text'}{'ru'}   = 'Список вылеченных вирусов';
$MESSAGE{3}{'text'}{'en'}   = 'List of removed viruses';
$MESSAGE{4}{'text'}{'ru'}   = 'IP-адрес компьютера пользователя, запросившего объект';
$MESSAGE{4}{'text'}{'en'}   = 'IP address of the client computer that has requested an object';
$MESSAGE{5}{'text'}{'ru'}   = 'URL запрошенного объекта';
$MESSAGE{5}{'text'}{'en'}   = 'Requested object URL';
$MESSAGE{6}{'text'}{'ru'}   = 'Выполненное над объектом действие';
$MESSAGE{6}{'text'}{'en'}   = 'Action performed on an object';
$MESSAGE{7}{'text'}{'ru'}   = 'Статус объекта';
$MESSAGE{7}{'text'}{'en'}   = 'Object status';
$MESSAGE{8}{'text'}{'ru'}   = 'Описание продукта';
$MESSAGE{8}{'text'}{'en'}   = 'Product description';
$MESSAGE{9}{'text'}{'ru'}   = 'Время создания сообщения';
$MESSAGE{9}{'text'}{'en'}   = 'Time of message creation';

my %COLOR_STATUS;
$COLOR_STATUS{'OK'}		= '#35d112';
$COLOR_STATUS{'INFECTED'}	= '#f90000';
$COLOR_STATUS{'CURED'}		= '#FFC859';
$COLOR_STATUS{'WARNING'}	= '#ffe500';
$COLOR_STATUS{'SUSPICIOUS'}	= '#E97659';
$COLOR_STATUS{'PROTECTED'}	= '#ff9400';
$COLOR_STATUS{'CORRUPTED'}	= '#E45959';
$COLOR_STATUS{'ERROR'}		= '#E45959';

my %COLOR_ACTION;
$COLOR_ACTION{'SKIP'}	= '#35d112';
$COLOR_ACTION{'DENY'}	= '#f90000';

my %PRIORITY;
$PRIORITY{'Highest'} 	= 1;
$PRIORITY{'High'} 	= 2;
$PRIORITY{'Normal'} 	= 3;
$PRIORITY{'Low'} 	= 4;
$PRIORITY{'Lowest'} 	= 5;

#in Notepad++, Plugins->MIME Tools->Base64 Encode
my $LOGO = q{
iVBORw0KGgoAAAANSUhEUgAAASwAAABECAYAAAA7rQj2AAAABGdBTUEAALGOfPtRkwAAACB
jSFJNAACHDwAAjA8AAP1SAACBQAAAfXkAAOmLAAA85QAAGcxzPIV3AAAKL2lDQ1BJQ0MgcH
JvZmlsZQAASMedlndUVNcWh8+9d3qhzTACUobeu8AA0nuTXkVhmBlgKAMOMzSxIaICEUVEm
iJIUMSA0VAkVkSxEBRUsAckCCgxGEVULG9G1ouurLz38vL746xv7bP3ufvsvc9aFwCSpy+X
lwZLAZDKE/CDPJzpEZFRdOwAgAEeYIApAExWRrpfsHsIEMnLzYWeIXICXwQB8HpYvAJw09A
zgE4H/5+kWel8geiYABGbszkZLBEXiDglS5Auts+KmBqXLGYYJWa+KEERy4k5YZENPvsssq
OY2ak8tojFOaezU9li7hXxtkwhR8SIr4gLM7mcLBHfErFGijCVK+I34thUDjMDABRJbBdwW
IkiNhExiR8S5CLi5QDgSAlfcdxXLOBkC8SXcklLz+FzExIFdB2WLt3U2ppB9+RkpXAEAsMA
JiuZyWfTXdJS05m8HAAW7/xZMuLa0kVFtjS1trQ0NDMy/apQ/3Xzb0rc20V6Gfi5ZxCt/4v
tr/zSGgBgzIlqs/OLLa4KgM4tAMjd+2LTOACApKhvHde/ug9NPC+JAkG6jbFxVlaWEZfDMh
IX9A/9T4e/oa++ZyQ+7o/y0F058UxhioAurhsrLSVNyKdnpDNZHLrhn4f4Hwf+dR4GQZx4D
p/DE0WEiaaMy0sQtZvH5gq4aTw6l/efmvgPw/6kxbkWidL4EVBjjIDUdSpAfu0HKAoRINH7
xV3/o2+++DAgfnnhKpOLc//vN/1nwaXiJYOb8DnOJSiEzhLyMxf3xM8SoAEBSAIqkAfKQB3
oAENgBqyALXAEbsAb+IMQEAlWAxZIBKmAD7JAHtgECkEx2An2gGpQBxpBM2gFx0EnOAXOg0
vgGrgBboP7YBRMgGdgFrwGCxAEYSEyRIHkIRVIE9KHzCAGZA+5Qb5QEBQJxUIJEA8SQnnQZ
qgYKoOqoXqoGfoeOgmdh65Ag9BdaAyahn6H3sEITIKpsBKsBRvDDNgJ9oFD4FVwArwGzoUL
4B1wJdwAH4U74PPwNfg2PAo/g+cQgBARGqKKGCIMxAXxR6KQeISPrEeKkAqkAWlFupE+5CY
yiswgb1EYFAVFRxmibFGeqFAUC7UGtR5VgqpGHUZ1oHpRN1FjqFnURzQZrYjWR9ugvdAR6A
R0FroQXYFuQrejL6JvoyfQrzEYDA2jjbHCeGIiMUmYtZgSzD5MG+YcZhAzjpnDYrHyWH2sH
dYfy8QKsIXYKuxR7FnsEHYC+wZHxKngzHDuuCgcD5ePq8AdwZ3BDeEmcQt4Kbwm3gbvj2fj
c/Cl+EZ8N/46fgK/QJAmaBPsCCGEJMImQiWhlXCR8IDwkkgkqhGtiYFELnEjsZJ4jHiZOEZ
8S5Ih6ZFcSNEkIWkH6RDpHOku6SWZTNYiO5KjyALyDnIz+QL5EfmNBEXCSMJLgi2xQaJGok
NiSOK5JF5SU9JJcrVkrmSF5AnJ65IzUngpLSkXKabUeqkaqZNSI1Jz0hRpU2l/6VTpEukj0
lekp2SwMloybjJsmQKZgzIXZMYpCEWd4kJhUTZTGikXKRNUDFWb6kVNohZTv6MOUGdlZWSX
yYbJZsvWyJ6WHaUhNC2aFy2FVko7ThumvVuitMRpCWfJ9iWtS4aWzMstlXOU48gVybXJ3ZZ
7J0+Xd5NPlt8l3yn/UAGloKcQqJClsF/hosLMUupS26WspUVLjy+9pwgr6ikGKa5VPKjYrz
inpKzkoZSuVKV0QWlGmabsqJykXK58RnlahaJir8JVKVc5q/KULkt3oqfQK+m99FlVRVVPV
aFqveqA6oKatlqoWr5am9pDdYI6Qz1evVy9R31WQ0XDTyNPo0XjniZek6GZqLlXs09zXktb
K1xrq1an1pS2nLaXdq52i/YDHbKOg84anQadW7oYXYZusu4+3Rt6sJ6FXqJejd51fVjfUp+
rv09/0ABtYG3AM2gwGDEkGToZZhq2GI4Z0Yx8jfKNOo2eG2sYRxnvMu4z/mhiYZJi0mhy31
TG1Ns037Tb9HczPTOWWY3ZLXOyubv5BvMu8xfL9Jdxlu1fdseCYuFnsdWix+KDpZUl37LVc
tpKwyrWqtZqhEFlBDBKGJet0dbO1husT1m/tbG0Edgct/nN1tA22faI7dRy7eWc5Y3Lx+3U
7Jh29Xaj9nT7WPsD9qMOqg5MhwaHx47qjmzHJsdJJ12nJKejTs+dTZz5zu3O8y42Lutczrk
irh6uRa4DbjJuoW7Vbo/c1dwT3FvcZz0sPNZ6nPNEe/p47vIc8VLyYnk1e816W3mv8+71If
kE+1T7PPbV8+X7dvvBft5+u/0erNBcwVvR6Q/8vfx3+z8M0A5YE/BjICYwILAm8EmQaVBeU
F8wJTgm+Ejw6xDnkNKQ+6E6ocLQnjDJsOiw5rD5cNfwsvDRCOOIdRHXIhUiuZFdUdiosKim
qLmVbiv3rJyItogujB5epb0qe9WV1QqrU1afjpGMYcaciEXHhsceiX3P9Gc2MOfivOJq42Z
ZLqy9rGdsR3Y5e5pjxynjTMbbxZfFTyXYJexOmE50SKxInOG6cKu5L5I8k+qS5pP9kw8lf0
oJT2lLxaXGpp7kyfCSeb1pymnZaYPp+umF6aNrbNbsWTPL9+E3ZUAZqzK6BFTRz1S/UEe4R
TiWaZ9Zk/kmKyzrRLZ0Ni+7P0cvZ3vOZK577rdrUWtZa3vyVPM25Y2tc1pXvx5aH7e+Z4P6
hoINExs9Nh7eRNiUvOmnfJP8svxXm8M3dxcoFWwsGN/isaWlUKKQXziy1XZr3TbUNu62ge3
m26u2fyxiF10tNimuKH5fwiq5+o3pN5XffNoRv2Og1LJ0/07MTt7O4V0Ouw6XSZfllo3v9t
vdUU4vLyp/tSdmz5WKZRV1ewl7hXtHK30ru6o0qnZWva9OrL5d41zTVqtYu712fh9739B+x
/2tdUp1xXXvDnAP3Kn3qO9o0GqoOIg5mHnwSWNYY9+3jG+bmxSaips+HOIdGj0cdLi32aq5
+YjikdIWuEXYMn00+uiN71y/62o1bK1vo7UVHwPHhMeefh/7/fBxn+M9JxgnWn/Q/KG2ndJ
e1AF15HTMdiZ2jnZFdg2e9D7Z023b3f6j0Y+HTqmeqjkte7r0DOFMwZlPZ3PPzp1LPzdzPu
H8eE9Mz/0LERdu9Qb2Dlz0uXj5kvulC31OfWcv210+dcXmysmrjKud1yyvdfRb9Lf/ZPFT+
4DlQMd1q+tdN6xvdA8uHzwz5DB0/qbrzUu3vG5du73i9uBw6PCdkeiR0TvsO1N3U+6+uJd5
b+H+xgfoB0UPpR5WPFJ81PCz7s9to5ajp8dcx/ofBz++P84af/ZLxi/vJwqekJ9UTKpMNk+
ZTZ2adp++8XTl04ln6c8WZgp/lf619rnO8x9+c/ytfzZiduIF/8Wn30teyr889GrZq565gL
lHr1NfL8wXvZF/c/gt423fu/B3kwtZ77HvKz/ofuj+6PPxwafUT5/+BQOY8/yUGUl9AAAAC
XBIWXMAAC4iAAAuIgGq4t2SAAAAB3RJTUUH4gQbChc5stHvPwAAMzlJREFUeF7tnQdgFNXW
x/9JtqV3klCkgxTpRTpSpQgiSFM6CoiIICBiR1AUfCqojyJNFEWagBSR3glFaui9hBTSe3a
T75zZWV+SnZmtwei3P70kezM7c8u5555z27hh0rB8uHDhwsU/AHfxpwsXLlyUeFwKy4ULF/
8YXArLWRj0QG6O+MHFPwaDAdDnih9clHRcCssZkMD7a7UoHxgMpCSJkS5KPHl5cCOFFe7nD
6SniJEuSjIuheUo+fkk7Gn4+JkBuPn+V3i8QlUgIV5oDC5KMFxv0Xew9ZU3ETV1Np6qUReI
izbGuyixeKB5/Q/E313YCgt3QhxmvTAGE1p3EqJebdURGR7uOHTxHF9AJewhxLsoQXBnkp6
KN3sPxujm7eCpVmNI0zaI1etx/FIU4EbXuOqtROJSWI6QkYZmtRpiaf8RYoSRjtVqo36FKv
j5yG5j41Cpxb+4KBFkZaJXg+ZY1H+kGGGkW816qBwWgU1Rp5CXnemqtxKIyyW0l+wsRAQG4
8dBY8SIwvSsVQ/H3voMVSLKAQbXoG6JgTqQULKelrw4WowozKDGLZEw878I8QsAclyTKCUN
l8KyB3YFc7Mxp/cQVAwKESPNCfP1h6eKXAvXcFbJgOst7gFWjH0bATpPMVICN2oW7Ba68T8
uShIuhWUP6ano36Q1BjZoJkZI0+rTt3D25lVA7XItSgQZ6WjbtDU6V6spRpgTnZqMqtMnIj
4p0VVvJRCXwrIVHpPKzcGMHgPECGl6LPsSt+JiAB9fMcbF3wqvkyMF9FWvQWKENON+WYKYp
DjA01uMcVGScCksW0lLwQttuqBycCkxwpzPdm3CpqMHgYBAYaLQRQkgKwvjWnVCndLlxAhz
3t26DmsP7XYpqxLMv19hZWc7bywiz0C9tAZTO3QXI8y5kRCLqetWAlqtawykpJCfDy8Pd7z
QtI0YYU5qDlnNy+ZRJxPkqrfigMcP/wpFPtuAssIS3R/pQIrAxocJ8FYIyfsVCHyNM8jKQM
MKlYGHsc4RwswM9KvbBLV55k+GUauWIp/zQIrNKrgMeWtI0TIwC3wNBT25NhzYxeH6sQd+p
nA/qec4Gui+UnJhTb0LgfMo5pPzyN+zR84Kkp2FxtVqo2m5CmKEOUNW/BcIDqEWYUMfrlSG
9sqwYr1QmzPVP/8udQ2XmaMoyiQ915a8cdXx/bj9cdly8DD9Tj853ob6lT9ehqwJP40OpQO
DKH3mCfTS6nD61nVAY2XDZKigvej68oEh0OebNzZWKRqVBneSE5Ccke7Y4j1uzJnpyP96FV
p9OwsHLvxJiXZgPIkLldyKpUNfxdBGLcTIwlyOi0b1KSNJ8MldtEZB0j3dKVQKCaU6dEeeT
MW5Ub9iyDfAQHWSnpmF3Dw9VU8eMg25yKU0Cc/y5FkvK57JkODVINfIQM/Lt1fpSeBG6VC5
e+BKzD3kCjNtYnpIfny0nihHLrKerVQZOJ96anA5FDJzsgS50+vzkKanRsKWMlut1nYEJjg
J9+9h/0ffoGXFKsa4Imy5eAY95s+GgeXNWoVF5f542fLUHvNJ1AqXoQeVwf2UJKRQB2eTDG
ek4fHHKgmTylL1olGpkJadAzcSEy+tGrlF2iU/NyY1CYnpafavIWMZpPuWo3bvQ21cXyQd3
H6jU1MQm5xEz1CJsTKwOHNiNWpos3OhI5n1ztVDQz/TNSpkU9mkaOkefJ2e8mJFm5FXWJTp
Fxs1w1cDRyOXtG2htkT3Dffxg9uwrtQ4w6x6kEBqMj7tOxyjmrdDJvckRdBQBpKyMtFy7nR
EW1MgSqSnohcplnXDX8e608fQe+EcgKeybelBC0KNqLSXD05P/RQhMgPpo9Ysx8LtGwD/AD
HGAiQMYZTnLePfR4XAYGqo0o2ZS9dACp4FNJEaQTYpflZecZTH3RfP4uD1Szh+4bQxf5RGx
frgikxKRMq3q5BFbhArLWfBCsuXhLzRu2NxgXtjU1nnZKNHvSZY0GcYdapu8oqZkp1Lecsk
eUslq4gVF+f57ANSOBfO4vcr55EYfdc4NsgN0hq5o3txunLnLKMGLV33o35ahIUHdlLZeYk
xFuDnUmcdv3SToFwM1ABN8LM4j1M2rsSyw3uNStYaSAlUK18JpyfPRAopw6JlxDkN8/VDZ1
KszSpXx7vtu1P9k2IqgJbayzZSvmwt5nIa7ZF1Ku8QDxXOvPcF1ORG6wvkjQmnNLSbOwO7r
0bRA3VirAScfragSLE+EZeMWYcvIzAnlwIpLJL7VLUaaWoP7IwIwFe1yiPBh+5FSk2A0y6D
vMJKS8HIZm2waPA4McIct0GdqBTLKD7gL1KS8VSdhtg1dpoYIU3n+Z9i+5kTgDc1PHuhQtf
CgN/GTEOHqjWRTEqw7dczceo2WYRKhaxEZiZa1aiDXWPeJCvCXBBYkTT+7C1cS0ywfjqcKi
6ChOLotM8F68NeuGFfionGkJUL8Oelc0alJWf5co+Z+BD5SzaJEc6n9psv4zxbRdTjC1D59
2nSCqtfHGOdrMjA9bj6z6MYs+576EmeBBmxZMGQpf5UzbqycpdMyqH91zNw4vY1kg2FtVkF
Yevx2kXkrz0gRpgzmjqvBfu2WXdPUugBdN3RyR+hWmiEGGnOurMn0Ju8hcpBwTj5/peCByR
Fj8WfY9OxI4CvHR7F/dvY9s7n6Mx7KyVYf/4knltAnb9GYYyWlRX/jayodyOv4K2zt6Ay5J
MF6wY9xbPCUdE1bhRU9CFV7Y6nO9VHZJlgkhXq6BiZe8urYPqCIU9al9kMVYjOP9Cispqzb
zu279ri+FIAel6rqk8IyorxJ8vjjTZPGwuSgz1kpaNLlRqSyorZT1bOrfhYm61CTk6ugptk
DRrqEZ8gF+/kpBmIJGEL54FjofeVyKuckDkRdpOKIliIDuaT63Fks7bInb0Eg1p1EgTe4mp
0uqZKaGnxgzlR0bdxgq1TmcYvCxWjVD4ZjjUIrpQVZc3XkTs0b8BIRWV15v4d9F82l6xoLa
6RnL3203fiX8zZOOINslbIHZWx2GWhTrd23SayyiqWrMCpG342ZsuSHHnr8HbkZUw/eBHZZ
Gklk+uXpvIQLFItWW3Z1FGnqVVIIqWmJWV2dPUhVIshr4rilLDDZrQRrpDMdKwY+LIYIU1U
7AN88NsqoGwFQcjshgsy4SHm9BwoRhh5sXFLlGZlIjF2Zh3uKBccKv5uzrkH9yXH5SxihUz
bQuPylRE54QPUpJ9sJTtUliWY718chZ+HvEq/Uf4sNMzmMmNXzOXoe9RjkCtij/skg9VVyr
JK7vnzDZrixfpPipHSjFz1HXLJTYaKLGeyLFecOoaT926LfzVnKrnfSE40ak9r4DKktvpN7
8FihDkr/zyMy7fIElUruLksb2T1+idnYMbxa0gO8IaBypbHrUKS0pFFymtnRCD8yJIKScsU
rs8kRZbrqcGCwxfpBtSGFJRh8Sus1CS8/nQf9KnXRIwwJ5UsoiFLv0Q6WwWWTHxLkOumiii
LuhLrbRYMHw/wYk5btQQrXY0a9VmZypBGSpm6VcXCflSUIwvrz0kfoenj1FPy5MW/lL4kU1
ff/4rcmFvGOiqKEJePxmXLGz9LcODWVcDTy9jQHjVZGXDz88MvIyaIEdJM3bwGx84cI+tKX
B9GFnVeTiaGrPjG+FmCdzp0R5PqtYRnWAW52xM790Lryo+LEeZMmP+Z0fuxJONkTQ29fF/4
NZcUlAfVAyua3t0bofyQp9CtWwP4jO6C6Y2rISSDlDCRRpZW47hUPPWAx65JB8jUR/EqLFJ
ATWvWx5xeL4gR0gxfuRDHr5J29XJwwR5nknqhQ6+9I0YUpvsTjeDB7gHvxLcZN0T4KYwzlb
ANzuwmHh7/rrFMeBr8X0rloBDMemmSMMkiKeRu7sIMrBzRbIWaxtoeJVwnKjX2jaM6UmDPj
YuYs3U1EMSTW2Ik4+2Lc1Gn8fOpSDGiMN5aHaZ16wc3kgOLytigRykfP7zZ4RkxwpweCz8n
nzxI2RLlx7Ayy9GjTgLVBxkf3GUEpGWjd7vaWPd4WWTlGpCfk4fMnFy837YWfqlSGgHZuci
j7/EMYrtYqg9WWDIUn8LidRxUEOtHvE4CI6+Rd16Jwpq926yfWVOClFWDajVRrZT8mMX7nX
sY02apEotCedAqFKQzXQpn4Ub/fdF3OLkdCcKnR4UHzw49Qsa17oS6VWsI9W8Gp0UhOZ482
2irLDgDsshfa9URLStVEyPMyczNxoRfvofBjeSuaJlymoNCMWXtMmTwjKwEfGJIi6pkMWUU
nk0sBLfNhzF4v+dAlJKZ6Np95Ty2RfGyICsMCmoGKnIvS5HLx9aV0CpIOW+v9Rh1KlQ/nG7
OCv/MzMbiKuHIUtF1pirI5s5Vvj6Kp5VxYlKT8eXA0Yjw9RcjzbmdGI+BvGCPLReFXtAqRK
Eb27oz/IU1SdIMbdIaQf7BRqVlE/lIVHCv3FXFs7K9P5WP1/DuCH51AILG9EGpd8bimSVfY
tGRPTh1V34Mw8SI5k+hZmVqzORCWMuna7+HekhX4ZnBr/a3KYS+NhDn7Nhd4Da6D4LHPI/g
V/ohkO5R5ePJmPjrT1h/7gSiLRw77aXWYFLbLiRC1LCLuobspufLp6V2OHVuvBjyESp0dtP
rkutlaV/jqFVLcOo6eR5yM9tqNe7ExeBDchnl2PXKW8IMvaTLzJAyq1K1Nl5p0U6MKExWLl
lCdH9ebmLWKXObKxhY0dBj9NSx3/LWQU1lz7ECHvRdsY0W/JlB1xqo7I1zh27QeyrPsDtfY
XFiqBAGteyI8W2Mp3DK8dLqZYjlY2ltWXwqBymgimRZ9avXVIyQhsd3JrbuKPRwVsONjyrs
AqdVhkrU2wnjb6bKcBIatQqZJLAJOh0SyQ2IS0vGb8cP4uUFc1B/xkT0IuV1PyVRvNocXhf
VqWYdarjWzxilq1TQ0/P4mQk6T5tCvEaLfMGqsVG06HvCPby8kETycC3mHr7Y8guem/Meqs
yYhNm7t4oXStO1ZgOU5fGVgg2T643qIz5T3sJoW7G6ONPo3HqTRbCG8rHTwow5zzqv2Piz0
fNQ0qWe3ph7cCeO37khRhRGTUr8zX7DhHVeZrLJMkEy+3WfIWKEOQuP7sH+86eMa/wKwrfi
emYlVjBwWklmd5cm95EXgzIU3/DyXepZqFMXZEP8nk6L52/HwosUG68vTdN44OeyZEzkyMs
qfcvJUIWEB4fhk14vihHSfLVnK7aTlcC+uMNwATyMx4R23eBthfLr37QNAnxJEKydZhcV1s
X7d8QIc9pUroYgXnMj15PZiannEdLAgVd6c5mFlKKf3vj18B5hMaES3es0ghcLnJVpExxf4
bEFnmtTsEOs6GvGIH6flxn4k+UdGoYMcvWmLJuLb3ljsgxBZFWX4peA5BUYr+N7UcPYEnVG
jDCnIllYIbx961Ec1scKIysbiwaNRbCCe3WbXPjePGZUmtworgclqHPJSkvBpI0/iRHmvNa
mKyo9xnlkS7IAZOn1q/ckOj9OHZoM45fOlR5o56LN450arGwKBs5jDtZWL41zYb7w0ech2c
8LG/84g1a344z3YWtL7Y5hJ67h1ah71EG6wy9Hj6mNKuNSEHc61C6LPk/EuQqLE5v4EKuGj
0MZFjYZ2MR/feVC52001ZOwUSMeJ2PWFoUHaoe3IusvSdnVKARZAIdvS/diTOWQMLSoWdf6
WRmrUSgfdoGoDM+dOY6NUdQLyhDi5QsdT0XbsuzCGfXiLLgTCg7FjF+W4mGWvGvbqz5Z17w
dphD5OPeAencZwn390YQVA8tQcZOahCFNWmLkk/KbsJlX1yxHHFvN1i5AJoWyl5T5vpuXxY
jClPbzxzudnhHGlP+yssi6CiBrdvoz/Y2fJRj/6w+Cwpfa5uNF91ly4ALOrj+KYxuPFQonN
kRi//rD5B26w0BypCeryp+spt+3/YnD9PfVf5zCmV8OY9GhKKSQNZZHHVSSzgO1E9Pgl84L
jumZpnQWwbkKi3qGsT0HoDWb2TKkkZbv8M0nggLg6VmH4Yylp2N2H/n1I1JMatdVMEkL9ch
KkIVy9MYVYduEHC83b0sNxp4ZSAchgVx9+pj4wRwdCYUHC7+0DPwzIOUcna/HtqjTYoQ5na
rVFqbnCylbamxHb10RP5jDs6nDWnSAO1uuTraOC0HpqlW2PL54QXk94swdG7GJXDxht4Ith
IWj9/w5yGalJMGwJq3RsUIVY/kw1Fbf7fUCqrGlLsGOKxfwzZ5txvFlCcHh7UcV07JQMyEN
NZIzUDM5/a9Qg0LDuFRUSM1CtgePT9FjVR7IIsuqXmIqet2OR+XUDCRTmRtImfEMoQcZVf2
ux8BPSL98Z+k8hUXm5RPVa+M/zyovYfj4t9WIunnN3Ce2F3JBy0aUQ7/G0huS5eDJAN5ryM
rOKsjXvxEXje2X+W040nR/vC4qVyJlnZYqxjwiqOJP3L0pfjDHi5SVWuglnaCx+Bam3k+mF
yw2SJ9kCAPk0vjzeip9kTRRxxh7/QoO3rgqRpjTh1zmOqXLi+NLxQArQnLblg4dj0CFrTp3
yfN4Z/nX5N+G2G7huqsRn5aEGTvkt1wtfnmKcQCeXGz/sDKY2Kqz+JfC8P7NL+k+Bp6YYmt
HAlbt2fS3LLWHsPAzg1zTQoE6yVxSUKZc8M98yhOPjyZq1cJ3OJLjObDSytGohK07SjhHYZ
FW1Oq8ML/vMKHHkmMz9Y6f7NwojL3YXCFy6PUY2OBJlOM1IhIoNakPOj9nNHetGZCm9ObTs
7bJrHsxsXrYa8aGbMMgt8OQzx+isPeSN1XzZmmjaDgA54tvIYxBeMBdZ8UaH2dCz1ZaU5XH
Lq/Un8lt/nD7evGDNJvHUGO+I6/0HYIU0cSeA9G4XEUxwpzUnCx04oWZltY6ycH1otJg4b7
tuM8r3CUo5x+AAR3JNYyJVtx5cpws0s3H9pFRIb8ZXE317pWVA11GNgLTs2RDQJHAcUHiz0
J/y8iCITMHWgvbAZ2gsKikHsZi6Quj0Ly8/BYIbjTd539KEkcKwtHV7Cao5wolS+31dt3EC
HO6ffuJ4IZKwadPDudD3RTGRQpBSmHxgT/wx6WzYoQ59cnsn8WzLrwm6FE0ZhbU1BQMb9zK
+FmCjNxc6B21HjgvXG8ad4STYA0/dwexi3eRNeD7yJSWL3UaTXjLkQyRwuZ2Hqsrkh6SkZ2
nI/E7bwyXoTRZ3O+NmiyMMzk1Pxm8eLoOZimMFTGT1v+AC2QJGo8JshOytGPjHmDYj/8VI8
yZ3uU5jCfDomvt+mKMOc0/eUtcasTCJU0yCd7T3RoiYGRH+A9t53DwHdYetQe0wi1P0TWXe
bZjCotvSqZunZr1MYCsHCX6Lf+GGjEpBmuP27AGcr2ebdQMET5+YkRheH/i1mMH8V3kfjHG
nMEt20PDVpY14xecX3Kvpmz6WYyQZnL77mhQsZpRaRU3rGy9fTGAB5xlyCbTXs+zYLb03EU
brZcOKrLShp6/i4Mbj5HiPo9g4Z7yQu1UYu6hT+OWqB0mvyj4pxOHKZ0Ss29Ub3mU96/2Ki
+NmNq+G5rwxl+7dkJIQJ6HJ3Vy8/uOJINUvpP+7dxJLORN/8LxNg6WJ1lo2/duxyU+tFKCi
kGl8NmzL8gu5p6+/VdjEiwN+LvlC9tpkinwT7NAbl+ap9amkOjNypoertBhOKawsrJQmgpg
y2gypxX4dNdm/Hp0rziA5yRYwVDvNff5wi8xLcgKwazV4cvtG5Ags+6qDSmWVjytaza7JIO
XD06dP4V1Z46LEebwgORmLhNh36KDSMkVVyhv2OXtKIY8HJ/2KbQSMzkmdlyKQjIrTxkhlY
SvZdePhI/3ho06dR0JP+zHwkOXEJaZjVStBtk8DlGccB3zIlRycZrWa4olfDyNAtfu3pKc0
RLQemLr6eOYf1h+aYQnWSjvdHyWfqN85zvm0gsnOSTGY0a3fqhX5jExVppnFn1uHNN1iudB
zy0VgQHffyt+LgyfCcbnzklxg5Tc1zt+EzpAy5B88KJcqUBunSZHj1JJ6QhKzUCgFYGvC0q
hNsq6imVPRmk5prBU7lg+crziEoaDN65gKpm7Vh+OZhWUmYx0vPxMP+hU0mNmV+Nj8c3ubd
TgdLgVH4MfI+XPLprHM4y2LCQNCkW/b2fhNB8mJ0O4jy/G9RtOjY23xdiPcDgcu7SscHjxH
x9sSFZVmFaHEe264s7H89GwjMKmbPru2mNkYfLYgJUKS8+KikzziulZeOPkNaR9twPz95xF
PvWqqWoPZKlVSovH7SNXb8wndxw8BsN7/MiNrVumHOYOHYcjb3wkXijNmjPHcC01mSRaptG
zdanRYMyiL5CSI2/5PlOzLl5q29m2JS8S8ImcrVp0xMQ20gPbJtrOm2G0knnW3FmQ8vvz0l
nM3k1Wm5Wwenhl5WLE8a4CmTZlBstT0cDo1BhyPQYx87fi4dKdSLAiPFy8A7E/7kVF6gyFj
lIGhxTWcx2eRQeeFZOBj1ft+t1/jB8ULACb4Z6XBPBFhXGbn04eRCoLMK/hoR5l4YEdwgFw
UtSgHumxClWtX5JAz+ZGPX3TL2KENG+264bQ0HBqiPa7hkGePggIjUD18DIYQPmd+dxgzO0
/EjvGv4fv+gxDWYXOgjlx6zqOX78kWJrWUpZ6xo93ncG+DZGYE3lVmN2J8/NGLjd6k1A6mZ
CQUihD1nqTSlUxuXMvIZ+rR0zAzlffwbjmltfX/UrWUx6vpeI0ysEySPLwEi+GVGBh7yHGR
mPnxEkGKd6mJE8rXxglxkgzY9s67D3/J6Cwfc1uSGnNJjczQWE7WUEOXLuAbedPAD42LqeQ
grRfAh99HOCDOArxRYJUXAKFWD8vZPJ579LGlYBDCuu4wlQ6w4fdNYooY3RfnElWBka06oh
WFUnJyPDeCjKJeYUuQ5V3jhrtoRvUcGVYx2crpcpvcTGD7rnu9FFsYIGTgS3PUbxAlWfo7B
zIPXLrGu7P+BoXp83GyhHjMe3pZzGuZQfUljg+RwqhB+fpfhsUzV0SnKXVSlPbdyPF7CHsC
eMTIhn7cmGZemXK4+70eTg68SN81nswpnXsgT51GyNYYfbTxA8nDuFHdvWssVJIJn45fQzf
Hd0nRkjzdre+EKw8O1B5qHA78aHsMISJ8qFh1ALJInTWQZkFIfc2Lvo23rbQqZrosogMC/q
Ow3t6GRI1PgaZ3UO+GweWPjXl04ssaR8K/NODZIrjhWvod40+T4hTwqHU3SYz/FMLZufPw8
ajLG8wVVhwaRP51Hjc1ejXUP6tyx/t3ExSQ8Jb0Fcnwe/Fa1xk4EV9rRs0t34siwWNFHL/7
+XPJGJ49i48MNTu3rpsYBCqf/SGXYqiP88WCe4GCaINsNBcKR2EMoPboU+72thaJgg+OXoE
ZOUat15YECp72BG5D3N4/MRGsvR6DJo/y9jY5NzBgrDi9lBj7r7tiC9yJnpBXmrdmTx/so7
tWAHPY0QJqUlozwukFRjUsAUmPt2LOkryBIqDwBDMX/89Yizcf+auzUiPe2CTFa6IIR93Pb
U4W8ofWr1BWLPllWuAwS0fx0P8sTc8EH8G+8E3K0dQVCxNGvp3R0Qg0rnNKsiXY+qUhOR9M
muvJ8SJEeaEevvis2cGOG/mhRRfk4rV0LFqLTGiMCnUQBeR+ydsGi2Yca0W2XExOHhN2srS
kbswjLdM2KJYyMrKio3G0mPy42MVg0NRircgyaxAtoS3VoM7ZGW9v2W1GGMdUzasxCp+CYK
f7e6GYIuRcuI9YRsqh6FXp3ro0akuDoT5CWto/El58WZVp0KNZcq6FbhHlom1PEhLRZsvpl
PnRMrKljEgkoWz5ALtuCK/PKV8QKBRxnLs8w4CqNzjb17DTAtK+PMeA6Bil9DajtJWQsLwP
HkbRd/sY+JmUgLm7djo3Akx6kT2V45AmtodalJEbKHz2Gff9nXRuUsD9OhYFx26NcTQVjWF
9VistPjY5KggHyTxyyg4rTIegWMKixp5dloaqs6YJEZIM4CsoUk9+gtHFzsM9YqLB8qPDSw
5sgd34u4JaRMUlilwMyQra8z6FcYLJejXoBlqV65uHOC2FnL7ZllY5rCWX+QRTz2YHeM/PO
PIjfGjLWux9YL8Jt6CDFj2NWbz2dvcY9rxTAH+Hpcbn09EP7c9Vgpt+7RA097NSHH5w5t6T
i0pLqdB9ZVP1vPjs98SI5TZevEsGn06FZE3LpCbx8tabNCgnDetDkNWzBcjpHBD9ycaULrs
XBzLXyGl99665cKCaSVOTia3nWclqaE7HepU9184LRxvLMXsjT8hJp4MDmsH2q1Bq8aQM9f
R7F4SUui+/mmZ6Pp0PeysFIYs0jh8TlYW1cGPjapgZsNKCCA5SiXLasK523jCdICfTJk7pr
C4Vry8kJcYj2nb1opx0szu3g+leHrXykFASTLTUa1aLTweLn1Yf0pONpYdP0QmPxU+D77yG
iFToP95avvszatYL7Mkgae1XydXQJiNM9oZlqGGdjk+FvP55AkZqoSQS8hWgC2bj01wvbGZ
TPnp+u0ss3fRFWTF8YOoMnMyfj7wh/GloM4Yj+By4DEWnsWj3jCSzPmnnm2Kjp3rY3OFUka
F5iw8vZBGVvDrPKtsgWE/zsc9PtNcZg2eRUhh5dy5hUMkD3I8XbMeygmbxqUbj0WozvKowb
60ciFSFDrBJyLK4uPneLExWVn2PksOocNyw5S1P5hNOvEpFt8e3W/f23Xk4Ofp89Aoltxts
rAEqHM7Ua00tSsqA5YlIVBbyMjGH+HBSNWwfLsJQw49HvCmb3nl6bhEcwEHhWLWtvXYYsEC
+GnQGGrfZPnYMwjPz6EGP6NrbzHCnF1XonD6MqWBVwtzzgoqLA4880M/voskV0mGEU1aGcd
DrD3gjyvIww27LkeJEdLUqlXP+llIKainZLd66KolYsT/WEKKqs3HUzCYTP9rfDIBH7PiLC
h7Qh5Ngd8dR0pqV7kQdO9Yn4SQGhnHOwWqY3JNvtq5Cb8qTGYwW16eBDW7uwp7CxVheQqLw
LsKg9IhpEC92F2zdoO8FNRJRpN13dfCzOSUdt3Qhc9ys3OgXxGSnejY+5hALndBJm5caaxf
a8b+rIGKlO+nIgVVPi1DmEn/n2TQb399MP3iRqJDXxL6cWOcjpc1KChtZ3TBdBd3smgNGP3
TQjwQrBNp2lWtibl9hhoHgm3tScjHb1ahOnrUIjNdhi9mz8TZ307jxK9HESkRjlK4uvEkKi
5dhe335Gc4vx402rgWyFo8NNh+/qSw8E6OF+s2Ea3L/1WhTXB5+QVg5aGdeGvzGszb/4dw6
oVmwmCMWPQ59j0Q3WBWbMUJKydOC1tcttahNbBl7OaBl8mC4pk2ORqUq4gvnh9u7PzsTQd1
nsfv3cCpaPlzzgbykUVpDngFDCm934/sww8nDooR5vDK8y0vTzaOoRbHJmz/ACzdsw0J4nH
JPEt6iV9vxjPIzoSqghVVjJcGKrKkBF2k9kCzKCrjvw7wozg2HnRqDLj+AN5kkRnEZpEvWF
fy9ekchcVQQ7kTfQ9Df1AaFwBGteiAZxtQT8KrtG2BTMgxbTsLb7eVYhtZOPvy03A3NAgNY
lLwRGKGWaifkIaKZIYeLheM6VvlXdj+DVvgsccqGhcyWgO5bMlkPR3iV/fLUIbfkC3sc7PD
LTTByoJcmVm/r8drZE3tJCUpvOGXFJlwb27sjwJ+pklx8U9no9MhjpTVAF6aosBYUiY9GzY
XZ9nsSYcbMrOzcVdBMbblt8gI6+gczGdAIIb/vBjnFc7mYta+8hbcWGHZOassC1tRpCTGrl
mKNPIe3mK3W+G1dXbBRcQyoVHhbJA3KV6DoGBSvT2xetdZPH+ZOlVWWJ4aBNHfhp+8hpcv3
hNcQp59ziTFdjSYXHzDo1BYDFXK70f2YOWfR8QIczi967gncSfFY61rSGZ/5dLl0K8+CacE
PK7zLp9rHRKChTXLIk3rgQyqnHQqAFPgWQo1XbekSmmcrFgWBw/tRpzMeBqfBjm6eXujcpG
ZXSkEKwoSsmvx8ltxQnypInj3uzX3U4KfxcsUeMEob6Hg8a2/i+JQViYob4dOHcViC+ul1v
D6OS5TG86s/wsqS365682EeDHCHB/uCHjMxdGskjWXm5aK0SsXiRHSPFe/KUbyS395Vt3ZF
iyV6cZzp9Dgqw8Rz7OSzjiPToqcXHxXtQyVm0FYv5dDbTGA4lbuOocD645gy8Zj2LeB6nZ/
FBJ1GuGQP09DHm55a7E5gjpfPlpZRrac3yUHhWDUT4txVmHbCifl8IT3AF4OYU2lpCTho+5
9SXFLN8691y7iLB/S5qbG+krhOBbiD2+xhzJlWzi2ggphamPxRAmNDqNXm48HmehZrwn8vU
ghWKtgDHqkiOa2FN4aLdTOmokpTkXBmG5f3M9Rgp8dGIyxP/wX+2/KH8CnIsvht4nT6TcSZ
Vtn2fgZVL9nWFZl5FAj1JmTFIePLw5cOoMpFhZzftHrBVQPowZvrYVvDZw/UhxlU9Px/Kbd
ZOU4ac2VGVSm5OJl+HvjtRY1EZCcDg21xUwqRzYa6qZk4qnoBDyWkYOHOi3yyILR0fWemdk
Y1rqW4D4q6QTnKyxKWFpaMgaRoCm9mvzJKjUxlY9hYStHSWmRFaYNCccAmTfj8rE1s3duRD
YPvrIA0r1eaVUL2pQMQcyEO9M/fqzhK4XhIZucPP5CwrP9xGHZ/YA1S0VgaLOnAMqLtcitd
WGEtChksySRy6cwsPLlhZX806ZA9emoFWmClFE2WbkT1ixHpsIkSLcadTCerRJu4DYXcj7S
Kb9ykprv7Erz8cPsX3/AQT7EUgZvtRa/v/aucRxVoQ3ZjFaNvlcfYOax62gZR3JtQTnYhdD
H0T+pmZjXoBLeblkDuW7uCMnIFl5Jz4f6scfDVpU3uYXBWbmkyNwxtFM9HHlMnHVW6Cidr7
AYbx+cvnTW4raAd55+DpUiygqLQSXhhCc9xCdd+ogR5jxITsD2k5H/GzzM0eNi2WCcLxuE4
OxcQVGoSOi5gD5qUo0alNhr0ec0sooW8BIAGb7sOYCsOysH3+l+xlM9peEFrfpHcW64Eygf
XhaN6zZGh1p10aFmPatDx1r10eWJhhBqwlkNQeeNE1eiMHnjKjFCmv+QVVLZVqtESKMbgry
8ZY9byeHOTeZvdsFjSdQ+Ri75UvacNqZ8QBDe6T/SOD7naFny93kogX5+eOqWMNg99SSfHS
Yvrw5hKi4qu48bVEGTng2xt3Qgoj3VCMzMQXByhrD26mqADnNrlEXrbo2xvDrpAX4LtIWyL
h6FxfgHUU+yEpEKL25gNynyjQ+NlSK6cIXIzkKp0o9hAA+sytBryTzSSCQEBdccpWdiBJmj
mVRJvH/Jn7T4FzXK4aK/p7H3NxWKWoPVp47h2kP5lfpj+5LQJFlQWiwQZFkGesuvCYpJSRD
Wkf2tY05W8lLLDoicNAN/vDINf4y1Pmx/5S3hqKHKvOrckcmFgnBVkVXyzbrvcUpBlniB7d
HJ5BryMIMtFh4pkCcfqyR+MEfYPCw0djHCGWh1uBgXjbFrvxcjpHm3Y0+0q9PEOKvuKF5aT
D12Fe6kRB7qNOh2MxZV7j8kn1dcYO1suI3xMAw975q/H9r2bILqvZshbFBblBvWHqEvtMYT
zzYly7gWrgRQu+SdFVZQfAqLK9nXD13mf4qbZCXJEezliw8HvmR0J4oKWk4WpnbogXCZ7SV
3khJwktddFdwgywWVY0BkeADWVgyFH7mU0d6e+LZ2OePsQ8HKIYUV/zAGs/jYZhlGNGsLr8
AgwTWVhZStu0aHFpXkT1w9f4d6NvLV/z9gcJZLaIJlKSwcbT6bhiSFxhvs6YNl4z8wdgzWp
IGu8VSrZeWLWcJnqgkvhHByoyaZ/X7PVmF5ihw8frZ88Cvw40MJ7V0FL3SmHghOSsPEP68h
kRQXn77Bawc/IwUm/N3UgdsCFwd/VykI19FPtlLJ1TNQPcaSVXfXk9odW3d8RhErKqFdFLh
egeJTWIxWi4SEeMyw5Bp26on25IIUcg1JCfgFBKNbnYZihDkf8R4otqzMVnTnI58smXWVIu
CWpcf6CsG4EUhCZ5AQYnIlvyPBkaMeWXjd+BRKpbUxeXrUJte2DrlScizls+CdcXTH/1fcV
Uiheh27eqkYIc3ABs3Qjo//lZkBLgQ1jmByOdtXrSlGmHOWF0M7a1NwQVhmPb3xmsJxxkxZ
vwAs5K1ovFbMHsXC36FHjYu6A39SEKwjuLUkaDXocjcB7WKTWDNaVBSF4Ev5Jt5ULgGkTP2
9lEOA+NOXrufA+wX5px9ZVgWv86HP7IEopKVoS3c+1JPwOehf7PldjDDHnSrv2z7DEMZT9S
a/Pi1FeH12tZAw4+cinHtwD6v5dUhSWzO4XrNz8WuNMjheLhjvNqhs7HG5IIpWOm+Zyc7B6
DXLxIjC8NWvtnkaWnZzpNxWJicHw5s9ZXxriwzJV6IEV8CFA1D5rdy/A9O3y1vEag93/Pby
ZFQJ4jcIK4xnsRzEx+A/fYeKEeYcvXMDtzN4JX8xNRPe9UFWfvXpr4sR0vSr1wTD+Ux4Plz
PJsVC17q7oWxqNl64Eg09ZVmwrvhP9JOHSyYevwY3Wy1iuoUvfffgmoPIn7MB+nmbYXAw5M
/9DQkLtqFcOlnQCkqr+BUWm/Nk0k78aSHu8QH/MlQLDcOalyYKx8oK4x9k0XzYta/4V3MWH
NxhdA/4/mYYK4X3LnXoWB8JrNFzSdkUVVYCVDCkKDcdP4RUGQFvXakaWvLbgaX2g2VloAZZ
Ya+27CBGmPMBn5PN+7VsEba/sOc7/1K4rqkDfH/lAsQobGHxVKnx3+EThE5P1jXMzIBPRDk
8X6eRGGHO9qjTSOX1UJJyI49NNab1xOWY+3j7tzVihDRf9xuOOnxYpq3HNJH7NenMdVRJyU
CmuEfPlL5UrQqdHiSg4x1qczZaWfxarkx3D+SoPYSXofImZ0dCKgU+cptfuqqEvMIiDcrnP
zsFnj3zUGHwoi/ECGlaVqyKvu2fAW5cweAOPaCRef6DlGQsOrRHqGxZWMhIWJP55EMLU6Xc
EO6np+JHfomBDIt5gWJiQuH7sGJNSsRX/V+SnWVi1vBLTmU36VJPp7CAz92NexvxgzOwS2n
aRsEdZCa4fNS8WNhRSLD5NXHPLhRPspWhQ+XqGMhvU5JyDfmoHwo/Dx0nRpiTTp3XhnMnjL
29VN1SORpfEWoOx6oEq8yKsuZ7a3T4eOcGHFN4zRgr4bm9B0PFY1nW1CFfw40/3x3jT1wjZ
aASDsjj86lMwcOQD3VuHl4/d5ssPdvqRsgjPYOtNBXdh7fhOBToHqYD/ZTwQPP6H4i/F8aQ
i6pk9bStUQcP09OQQpYET80bQxb8dZ74kI9V4QFBhcb6FxoNbty7jWi6TyvqKeLSUwrczxj
4dVSdq9fBb9F3MaNLb+G8dt77ZPo7b3/xJN+bF95FXj5PtaigsBhOF1ecpfTx3/MMOB99Bx
2rPwEDFWBSZvpfz03LzkYEW2HXL+IBz0KxAmZllZaGd8ilGNm0tXgjc747sgeL95E7zMq1a
DoobZ6kLHvWbyoc+vawSF51VGas7M7xvkfekO0sqDGOadeV8pUlnIppeqajgafp9VR2C/du
w0O2bEz5NeShPLn27arVQDLVPwfTd9KpbPmEzpl/iOOR1nSSVBZ3qa7ukAXVnDo5nskrLJ+
ZyMzJRftqtbDz6gXE8CwvKx4T1DnN6D0EIxTqbe2pY/h691aSW615vfFHuseIjs8gS58jPt
/43FRqG5kkx3wS7bn7d4SO2iKcZ/IoFh3ZhyntuwnWY8EyMt43UxgnzSCr5iBvDOd0WUKnx
dy951AhKxd3vLRIISuK33JjCkkUYskCaxGThHVlghDrSzLK47yW2guhombV9v5D+JISjNOp
C93XvuCBeJ0GP1QORzorT5l264ZJw6TVNQmcjio5kBST8SWcBXETXph6lxe2sR9uLSzEVJm
8TUXO8uOVy+kGA3RUicZFe/9LHv/mpdLgFu/94kw5c2yBn0XP9dfphN5MeCmnCD9X56FGuj
6XGjhvaSDhpzT0btrG6MbKwILb5uuZOHbjsvT4FT+TQqiXl2DqFl2kqCKLJIEENYstAmsas
rVQusJ9/SlfeWbPdASuUneqvxhqzHlcNyaBo3pnhRxMZVt0BpGtFH4F1l1e2mJN4zbBMknK
MczHRzYPfChjJlkkcVxnXH6cnvgYDGz2FH586Q3xKmlCpo3GQ16D5ynx2jCGZCHCN4CSYDB
7vjs9Kyk7x1hvVjT+v0hPR1BgEFmibpJ54rFeT1JUN0ydphL8fUpHKKWD4VKXSgk/RUX/Zt
O9WYHJXihBYK5eeKEqawcbcimLOyUmlj0ihbvJKyyGhYsLXQr+lo1H7wpwQQpTtPKPFRbXC
YItcQ1HOVtZmeC0cX4lhEV4Lq/3YrcmOQH1qPc+NP59YVpcjh+P78eL8+eA3zwsK7hKz2RY
OXJ5OBNr6sARuDEVza+SLDFS37GEcE9uLjL54GguPw4M1VvdClVxatps42cZPtyxER/wnj9
Lm4NJ8cs+29564xX9crLAcBmxW2yNiuD78PWWLuVruCx5CtGK2xbC1ustwVnnIHNfZYXloj
AsAGSu161cHacmfyxGSpNH13r0bQuUr2QUCBd/LylJ6Eau94ZRUxTHG3kPbLPP3kY6X2JSd
P9klJRfUWyVU1vubTWUBoVkFIOZ8i+FKyclGZ3rNsbh1z8UI6Ux0LUd5s0ESoW7lNXfDddb
fCz6NmiGVSMnKiqrjFzj8pZ0ffa/Q1kxnF9rg61I3cPhIN5bBpfCspbMdLzaoTu2jpmq6AY
yk9avwO6LxXA4mgsbIWWVk42BT3XFqlGT4W1h3Gf0L4tx6NxJ5dlnF38rLoVlDTxOotZgXt
/hljoAvL1lDb7kwwF5sJZ7DBd/H3o9SgcGY0H/EWKEPHP2bsUKnvXmt8e46q3E4lJY1sAzT
BnpWHRolxghzS+nIvExb2j1DTB+x8Xfi4cK92Mf4PvI/WKENN/s347Ja5YDZXkTdHGMy7hw
Fq5WZQ3c45KbME/hKJplxw+iH7+WnzfS/lvGP/7pcL2pVPhk12Yxwpz5B3fiVZ4R5C1aLsu
qxONSWNbCL9+8eQ1Ljpi/ceerfdsxbP6ngttocX2Mi0eLpxfuXjqPDVHmb+GZf2Anxiz4zL
j4WVgq4KKk41JY1sK9L4Xl5BZmiadfGvLz8ObGn/A6v8KJN267hL7kwbOEwaGYtanwAYDjy
QUcs3weUKq0y33/B+GqKVug3nrfhdO4+MD4WqiBy7/BZ1vWCufYO31xpwvnodHgyK0b2HzB
+Gr6Zxd9jrl/bDC+bcjlBv6jcC0ctZWcHNQszYcB5iHq5mWjZeWi5JObg0aPVcSNpEQ8jIk
2jjW6+MfhUlj2IBzxQcVW3C8tdeFcuN54E6s1G4ddlEhcLqE98AmULmX1z4PrzaWs/sEA/w
d0dl52KiiATwAAAABJRU5ErkJggg==
};

main();

sub send_email
{
    my $email_body = shift;

    my $msg = MIME::Lite->new(
                              From    =>  EMAIL_FROM,
                              To      =>  EMAIL_TO,
                              Subject => '%VERDICT%',
                              Type    => 'multipart/related'
                             );
    $msg->attach(Type => 'text/html', Data => $email_body);
    $msg->attach(Type => 'image/png', Filename => 'image001.png', Id => 'image001.png', Data => decode_base64($LOGO));
    $msg->replace('X-Mailer' => '%PRODUCT%');
    $msg->add('X-Priority' => $PRIORITY{'Highest'});
    $msg->send('smtp', SMTP_SERVER, Debug => DEBUG);
}

sub set_email_body
{
    my $language = shift;

    my $hostname = get_hostname();

    my $email_body = qq{
			<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
			<html xmlns="http://www.w3.org/TR/REC-html401">
			    <head>
			    <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
			    </head>
			    <body>
			          $MESSAGE{9}{'text'}{$language}: %DATE%<br>
				  $MESSAGE{7}{'text'}{$language}: <b><font color='$COLOR_STATUS{%VERDICT%}'>%VERDICT%</b></font><br>
				  $MESSAGE{0}{'text'}{$language}: <b>%VIRUS_LIST%</b><br>
				  $MESSAGE{1}{'text'}{$language}: %WARN_LIST%<br>
				  $MESSAGE{2}{'text'}{$language}: %SUSP_LIST%<br>
				  $MESSAGE{3}{'text'}{$language}: %CURED_LIST%<br>
				  $MESSAGE{6}{'text'}{$language}: <b><font color='$COLOR_ACTION{%ACTION%}'>%ACTION%</b></font><br>
				  $MESSAGE{5}{'text'}{$language}: %URL%<br>
				  $MESSAGE{4}{'text'}{$language}: %CLIENT_ADDR%<br><br>
				  <img src='cid:image001.png' alt='Kaspersky Antivirus for Linux Proxy Server' width='300' height='68'><br>
				  <font color='#bfbfbf'>This message generated by %PRODUCT% on $hostname</font>
			    </body>	
		       </html>
             };
    return $email_body;
}

sub get_hostname
{
    return `hostname`;
}

sub main
{
    #ru or en
    my $email_body = set_email_body('ru');
    send_email($email_body);
}
