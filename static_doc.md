# Raccordement Intra-DC 
## Introduction 

Afin d'assurer la résilience inter-site,  un projet nommé PCI-IT a été lancé courant 2017 pour étendre HR & TRP. <br />
Les 2 DC sont donc raccordés de façon direct pour former qu'une unité logique. <br />
Des Fibres Noires ont été installées pour assurer le raccordement des 2 DC. <br />
La solution OTV (Overlay Transport Virtualization) a été retenue pour assurer l'inter-DC au niveau L2. <br />

## Raccordement 

Des Fibres noires sont utilisées pour raccorder les 2 DC.
Elles sont plugées sur les Coeurs de réseaux (N7K) sur les 2 sites coté FCT / MGT

| Équipements | Zone | Interface | Destination | REF DGRE | 
| ----------- | ---- | --------- | ----------- | -------- |
| PR-ACH2-L1T2-RC-FCT01 | FCT HR | Eth3/1 | PR-TR1-RC-FCT01 | DOS0107 |
| PR-ACH3-L1T2-RC-FCT02 | FCT HR | Eth3/1 | PR-TRNG1-RC-FCT02 | DOS0112 |
| PR-ACH2-L2T1-RC-MGT01 | MGT HR | Eth1/13 | PR-TR1-RC-MGT01 | DOS0108 |
| PR-ACH3-L2T1-RC-MGT02 | MGT HR | Eth1/13 | PR-TRNG1-RC-MGT02 | DOS0113 |
| PR-TR1-RC-FCT01 | FCT TRP | Eth3/1 | PR-ACH2-L1T2-RC-FCT01 | DOS0107 |
| PR-TRNG1-RC-FCT02 | FCT TRP | Eth3/1 | PR-ACH3-L1T2-RC-FCT02 | DOS0112 | 
| PR-TR1-RC-MGT01   | MGT TRP| Eth1/13 | PR-ACH2-L2T1-RC-MGT01| DOS0108 |
| PR-TRNG1-RC-MGT02 | MGT TRP| Eth1/13 | PR-ACH3-L2T1-RC-MGT02  | DOS0113 |

## Équipements

| Équipements | Zone| Version Hardware | Version Software | IP | Crédentials |
| ----------- | --- | ---------------- | ---------------- | -- | ----------- |
|  PR-ACH2-L1T2-OTV-FCT01 | FCT HR | ASR1000 | 16.6.2 | 10.45.245.111 | X/X |
|  PR-ACH3-L1T2-OTV-FCT02 | FCT HR | ASR1000 | 16.6.2 | 10.45.245.112 | X/X |
|  PR-ACH2-L2T1-OTV-MGT01 | MGT HR | ASR1000 | 16.6.2 | 10.45.245.109 | X/X |
|  PR-ACH3-L2T1-OTV-MGT02 | MGT HR | ASR1000 | 16.6.2 | 10.45.245.110 | X/X |
|  PR-TR1-L1T1-OTV-FCT01 | FCT TRP | ASR1000 | 16.6.2 | 10.24.191.111 | X/X |
|  PR-TRNG1-L1T1-OTV-MGT02 | FCT TRP | ASR1000 | 16.6.2 | 10.24.191.112 | X/X |
|  PR-TR1-L1T2-OTV-MGT01 | MGT TRP | ASR1000 | 16.6.2 | 10.24.191.109 | X/X |
|  PR-TRNG1-L1T1-OTV-MGT02 | MGT TRP | ASR1000 | 16.6.2 | 10.24.191.110 | X/X |

## Détails d'ingénierie 
### Introduction OTV 

Overlay Transport Virtualization (OVT) est une technologie CISCO qui permet d’étendre un domaine de niveau 2 sur plusieurs équipements. Cela permet de relier plusieurs Routeurs même si ceux-ci sont géographiquement éloignés. <br />

Cette extension se passe au niveau 2 via un algorithme sur lequel nous n’avons pas de moyen d’action/modification et qui est géré par l'OS Cisco. Ainsi, s’il y a deux sites à relier via OTV, les VLAN (couche 2) seront répartis. <br />

### Principe de fonctionnement

OTV repose sur une technologie VPN pour relier 2 sites distants. <br />
La fonctionnalité OTV va encapsuler les flux L2 dans un tunnel GRE pour faire transiter les flux. <br />

Illustration:
![image](/uploads/93c764e5ed6fcd3034fda1c767553e41/image.png)

### Cinématique des flux Globale: <br />
  1/ Envoi du L2 sur le coeurs <br />
  2/ Si le L2 se trouve sur le site distant, forward sur les InternalInterface (sans encapsulation) vers les équipement OTV <br />
  3/ Encapsulation dans l'Overlay <br />
  4/ Forward des flux sur les join interface (avec encapsulation)<br />
  5/ Passage dans la fibre noir via le coeur <br />
  6/ Arrivée sur le coeur distant via la fibre noir <br />
  7/ Forward des flux sur la JoinInterface pour décapsulation <br />
  8/ Décapsulation des flux Overlay <br />
  9/ Forward du L2 décapsulé sur les InternalInterface (sans encapsulation) <br />
  10/ Envoi du L2 sur le switch de distribution depuis les coeurs <br />

### Détails d'ingénierie :

<p> L'ensemble des VLAN sont instanciés sur les 2 OTV des 2 sites </p> 
<p> Un principe de séparation des VLANs entre les 2 équipements FCT01/02 a été réalisé pour répartir la charge </p>
<p> La répartition est la suivante : </p>
 *  Vlans pairs: FCT01
 * Vlans impairs: FCT02 

OTV-FCT01
```
 0    4084 4084 *PR-ACH2-L1T2-OTV-FC active              Po11:SI4084
 0    4085 4085  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI4085
```
OTV-FCT02
```
 0    4084 4084  PR-ACH2-L1T2-OTV-FC inactive(NA)        Po11:SI4084
 0    4085 4085 *PR-ACH3-L1T2-OTV-FC active              Po11:SI4085
```

### Détail de fonctionnement dans notre environnement
 * Exemple avec 2 machines inter-DC
  * Vlan1070
  * Machine source: 10.44.70.163 (sw50275fct) / 0050.5686.7df9 / TRP
  * Machine destination: 10.44.70.121 (su13990fct) / 0050.5686.01af / HR

![image](/uploads/37aa7cfc26182de0518abc428dab99f0/image.png)

#### Cinématique des flux sw50275fct (TRP) => su13990fct (HR): <br />
 1/ Les flux remontent via les N5K sur les routeurs N7K de Trappes pour aller joindre la machine destination sur Achères (SU13990) <br />
 2/ Sur les routeurs de Trappes, l'@mac indique que la machine passe par OTV <br />
 3/ Les flux vers l'@mac destination achères passent par le Po19 du routeur N7K de Trappes vers les routeurs ASR-OTV  de Trappes via l'InternalInterface sur l'OTV pour encapsulation <br />
 4/ Encapsulation dans l'Overlay 99 <br />
 5/ Forward des flux via le Po18 (JoinInterface) depuis le routeur ASR-OTV de Trappes sur le routeur N7K de Trappes <br />
 6/ Forward des flux depuis le routeur N7K de Trappes vers Achères via l'interco Inter-DC (Fibre Noir) <br />
 7/ Forward des flux depuis la fibre noir sur le routeur N7K d'Achères <br />
 8/ Forward via Po18 du routeur N7K de Achères (Po18) vers ASR-OTV Achères (JoinInterface) pour décapsulation <br />
 9/ Decapsulation Overlay 99 <br />
 10/ Forward des flux @mac_HR sur le po19 (InternalInterface) depuis AST-OTV Achères vers le N7K Achères <br />
 11/ Forward vers le switch concerné via le Po205 <br />

#### @Mac Source 

```
PR-TR1-RC-FCT01
* 1070     0050.5686.7df9    dynamic     ~~~      F    F  Po6
```

#### Check de l'@mac "Machine sur HR" sur le Routeur (N7K) de Trappes:
```
* 1070     0050.5686.01af    dynamic     ~~~      F    F  Po19
```
 * L'interface Po19 correspond à l'interconnexion OTV non encapsulé 

#### Check de l'@mac "Machine sur HR" sur le Routeur OTV (ASR) de Trappes:

```
1070   0050.5686.01af 10.44.70.121     00:00:32       Remote
```
 * On peut voir qu'il est en "Remote" ce qui veut dire que la machine se trouve sur le site distant

#### Check de l'@mac "Machine HR" sur le routeur OTV (ASR) de Acheres:

```
   AED MAC address    Policy  Tag       Age  Pseudoport
   1   0050.5686.01AF forward dynamic_c 1386 Port-channel11.EFP1070
```

 * L'ASR n'est pas un SW donc il n'y a pas de table d'@macs sur l'équipements.
 * Une autre commande permet de voir les @mac & Po/Vlan interconnectés.


#### Check de l'@mac "Machine sur HR" sur le Routeur (N7K) de Achères: 

```
PR-ACH2-L1T2-RC-FCT01
* 1070     0050.5686.01af    dynamic     ~~~      F    F  Po205
```

## Troubleshooting OTV: 

* Exemple d'interfaces UP 
  * Interfaces: ```sh interfaces descriptions```

```
Te0/1/0                        up             up       S_PR-ACH2-L1T2-RC-FCT01_Eth1/40_vpc18
Te0/1/1                        up             up       S_PR-ACH3-L1T2-RC-FCT02_Eth1/40_vpc18
Te0/1/2                        up             up       S_PR-ACH2-L1T2-RC-FCT01_Eth2/40_vpc19
Te0/1/3                        up             up       S_PR-ACH3-L1T2-RC-FCT02_Eth2/40_vpc19
Gi0                            up             up       S_PR-ACH2-L1T1-SW-MGT3_Gi1/0/20
OTV-Site                       up             up       
Ov99                           up             up       S_ov99_encapsulation_otv
Po10                           up             up       S_PR-ACH2/3-L1T2-FCT01/2_Po18_vpc18
Po11                           up             up       S_PR-ACH2/3-L1T2-FCT01/2_Po19_vpc19
Tu0                            up             up  
```

 * Vérifications des peers: ```sh otv adjacency ```

```
Overlay Adjacency Database for overlay 99
Hostname                       System-ID      Dest Addr       Site-ID        Up Time   State
PR-TRNG1-L1T2-OTV-FCT02        0000.0000.0004 100.0.0.4       0000.0000.0091 9w0d      UP   
PR-TR1-L1T1-OTV-FCT01          0000.0000.0003 100.0.0.3       0000.0000.0091 19w2d     UP   
PR-ACH3-L1T2-OTV-FCT02         0000.0000.0002 100.0.0.2       0000.0000.0099 28w3d     UP   
```

 * Vérification des ARP sur les OTV : ```sh otv arp-nd-cache ```
  * Les ARP des remotes remontent seulement

```
Overlay99 ARP/ND L3->L2 Address Mapping Cache
BD     MAC            Layer-3 Address  Age (HH:MM:SS) Local/Remote
66     02a0.98b9.9b41 10.30.66.79      00:02:14       Remote
100    0000.0c9f.f001 10.24.0.1        00:00:01       Remote
100    b414.89e0.f5c1 10.24.0.2        00:00:00       Remote
100    b414.89de.4d41 10.24.0.3        00:00:00       Remote
100    0017.a477.043a 10.24.0.12       00:03:57       Remote
100    0050.5686.6691 10.24.0.13       00:02:02       Remote
100    0050.5695.1fca 10.24.0.21       00:00:21       Remote
```

 * Vérification des @macs locales sur les routeurs OTV: ``` sh bridge-domain``` (ex pour le Vl104)
  * Comme les ASR ne font pas réellement de switching, il n'y a pas de table d'@mac.
  * Néanmoins il y a bien une table de "Bridging L2" pour le fonctionnement OTV.

```
Bridge-domain 104 (2 ports in all)
State: UP                    Mac learning: Enabled
Aging-Timer: 1800 second(s)
    Port-channel11 service instance 104
    Overlay99 service instance 104
   AED MAC address    Policy  Tag       Age  Pseudoport
   1   005D.73C2.F43C forward static_r  0    OCE_PTR:0x4a285840
   1   6CB2.AECC.26BC forward dynamic_c 1789 Port-channel11.EFP104
   1   B414.89DE.4D41 forward static_r  0    OCE_PTR:0x4a285840
   1   0000.0C9F.F001 forward static_r  0    OCE_PTR:0x4a285840
   1   02A0.98B9.8FC5 forward dynamic_c 1787 Port-channel11.EFP104
   1   02A0.981D.E457 forward static_r  0    OCE_PTR:0x4a285840
   1   B414.89E0.F5C1 forward static_r  0    OCE_PTR:0x4a285840
   1   02A0.9814.6649 forward static_r  0    OCE_PTR:0x4a285840

```

 * Vérification des VLAN portés par les Routeurs OTV : ```sh otv vlan```
  * Vlans Pairs: FCT01
  * Vlans Impairs: FCT02

```
Overlay 99 VLAN Configuration Information
 Inst VLAN BD   Auth ED              State                Site If(s)          
 0    3    3     PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI3
 0    4    4    *PR-ACH2-L1T2-OTV-FC active              Po11:SI4
 0    5    5     PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI5
 0    19   19    PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI19
 0    27   27    PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI27
 0    35   35    PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI35
 0    39   39    PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI39
 0    43   43    PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI43
 0    47   47    PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI47
 0    51   51    PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI51
 0    55   55    PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI55
 0    59   59    PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI59
 0    63   63    PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI63
 0    64   64   *PR-ACH2-L1T2-OTV-FC active              Po11:SI64
 0    66   66   *PR-ACH2-L1T2-OTV-FC active              Po11:SI66
 0    68   68   *PR-ACH2-L1T2-OTV-FC active              Po11:SI68
 0    74   74   *PR-ACH2-L1T2-OTV-FC active              Po11:SI74
 0    100  100  *PR-ACH2-L1T2-OTV-FC active              Po11:SI100
 0    101  101   PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI101
 0    102  102  *PR-ACH2-L1T2-OTV-FC active              Po11:SI102
 0    103  103   PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI103
 0    104  104  *PR-ACH2-L1T2-OTV-FC active              Po11:SI104
 0    105  105   PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI105
 0    106  106  *PR-ACH2-L1T2-OTV-FC active              Po11:SI106
 0    107  107   PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI107
 0    132  132  *PR-ACH2-L1T2-OTV-FC active              Po11:SI132
 0    134  134  *PR-ACH2-L1T2-OTV-FC active              Po11:SI134
 0    136  136  *PR-ACH2-L1T2-OTV-FC active              Po11:SI136
 0    137  137   PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI137
 0    138  138  *PR-ACH2-L1T2-OTV-FC active              Po11:SI138
 0    139  139   PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI139
 0    140  140  *PR-ACH2-L1T2-OTV-FC active              Po11:SI140
 0    141  141   PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI141
 0    142  142  *PR-ACH2-L1T2-OTV-FC active              Po11:SI142
 0    143  143   PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI143
 0    144  144  *PR-ACH2-L1T2-OTV-FC active              Po11:SI144
 0    152  152  *PR-ACH2-L1T2-OTV-FC active              Po11:SI152
 0    156  156  *PR-ACH2-L1T2-OTV-FC active              Po11:SI156
 0    160  160  *PR-ACH2-L1T2-OTV-FC active              Po11:SI160
 0    200  200  *PR-ACH2-L1T2-OTV-FC active              Po11:SI200
 0    201  201   PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI201
 0    202  202  *PR-ACH2-L1T2-OTV-FC active              Po11:SI202
 0    203  203   PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI203
 0    250  250  *PR-ACH2-L1T2-OTV-FC active              Po11:SI250
 0    300  300  *PR-ACH2-L1T2-OTV-FC active              Po11:SI300
 0    301  301   PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI301
 0    302  302  *PR-ACH2-L1T2-OTV-FC active              Po11:SI302
 0    303  303   PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI303
 0    304  304  *PR-ACH2-L1T2-OTV-FC active              Po11:SI304
 0    400  400  *PR-ACH2-L1T2-OTV-FC active              Po11:SI400
 0    500  500  *PR-ACH2-L1T2-OTV-FC active              Po11:SI500
 0    501  501   PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI501
 0    502  502  *PR-ACH2-L1T2-OTV-FC active              Po11:SI502
 0    503  503   PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI503
 0    504  504  *PR-ACH2-L1T2-OTV-FC active              Po11:SI504
 0    505  505   PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI505
 0    506  506  *PR-ACH2-L1T2-OTV-FC active              Po11:SI506
 0    507  507   PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI507
 0    508  508  *PR-ACH2-L1T2-OTV-FC active              Po11:SI508
 0    509  509   PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI509
 0    848  848  *PR-ACH2-L1T2-OTV-FC active              Po11:SI848
 0    900  900  *PR-ACH2-L1T2-OTV-FC active              Po11:SI900
 0    901  901   PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI901
 0    902  902  *PR-ACH2-L1T2-OTV-FC active              Po11:SI902
 0    903  903   PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI903
 0    904  904  *PR-ACH2-L1T2-OTV-FC active              Po11:SI904
 0    905  905   PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI905
 0    906  906  *PR-ACH2-L1T2-OTV-FC active              Po11:SI906
 0    907  907   PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI907
 0    908  908  *PR-ACH2-L1T2-OTV-FC active              Po11:SI908
 0    909  909   PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI909
 0    910  910  *PR-ACH2-L1T2-OTV-FC active              Po11:SI910
 0    911  911   PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI911
 0    912  912  *PR-ACH2-L1T2-OTV-FC active              Po11:SI912
 0    913  913   PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI913
 0    914  914  *PR-ACH2-L1T2-OTV-FC active              Po11:SI914
 0    915  915   PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI915
 0    916  916  *PR-ACH2-L1T2-OTV-FC active              Po11:SI916
 0    917  917   PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI917
 0    918  918  *PR-ACH2-L1T2-OTV-FC active              Po11:SI918
 0    919  919   PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI919
 0    920  920  *PR-ACH2-L1T2-OTV-FC active              Po11:SI920
 0    921  921   PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI921
 0    922  922  *PR-ACH2-L1T2-OTV-FC active              Po11:SI922
 0    923  923   PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI923
 0    924  924  *PR-ACH2-L1T2-OTV-FC active              Po11:SI924
 0    925  925   PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI925
 0    926  926  *PR-ACH2-L1T2-OTV-FC active              Po11:SI926
 0    948  948  *PR-ACH2-L1T2-OTV-FC active              Po11:SI948
 0    960  960  *PR-ACH2-L1T2-OTV-FC active              Po11:SI960
 0    1027 1027  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI1027
 0    1066 1066 *PR-ACH2-L1T2-OTV-FC active              Po11:SI1066
 0    1070 1070 *PR-ACH2-L1T2-OTV-FC active              Po11:SI1070
 0    1074 1074 *PR-ACH2-L1T2-OTV-FC active              Po11:SI1074
 0    1078 1078 *PR-ACH2-L1T2-OTV-FC active              Po11:SI1078
 0    1082 1082 *PR-ACH2-L1T2-OTV-FC active              Po11:SI1082
 0    1090 1090 *PR-ACH2-L1T2-OTV-FC active              Po11:SI1090
 0    1094 1094 *PR-ACH2-L1T2-OTV-FC active              Po11:SI1094
 0    1140 1140 *PR-ACH2-L1T2-OTV-FC active              Po11:SI1140
 0    1141 1141  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI1141
 0    1144 1144 *PR-ACH2-L1T2-OTV-FC active              Po11:SI1144
 0    1152 1152 *PR-ACH2-L1T2-OTV-FC active              Po11:SI1152
 0    1156 1156 *PR-ACH2-L1T2-OTV-FC active              Po11:SI1156
 0    1200 1200 *PR-ACH2-L1T2-OTV-FC active              Po11:SI1200
 0    1300 1300 *PR-ACH2-L1T2-OTV-FC active              Po11:SI1300
 0    1301 1301  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI1301
 0    1304 1304 *PR-ACH2-L1T2-OTV-FC active              Po11:SI1304
 0    1305 1305  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI1305
 0    1306 1306 *PR-ACH2-L1T2-OTV-FC active              Po11:SI1306
 0    1400 1400 *PR-ACH2-L1T2-OTV-FC active              Po11:SI1400
 0    1401 1401  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI1401
 0    1402 1402 *PR-ACH2-L1T2-OTV-FC active              Po11:SI1402
 0    1403 1403  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI1403
 0    1408 1408 *PR-ACH2-L1T2-OTV-FC active              Po11:SI1408
 0    1409 1409  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI1409
 0    1410 1410 *PR-ACH2-L1T2-OTV-FC active              Po11:SI1410
 0    1411 1411  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI1411
 0    1412 1412 *PR-ACH2-L1T2-OTV-FC active              Po11:SI1412
 0    1413 1413  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI1413
 0    1601 1601  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI1601
 0    1602 1602 *PR-ACH2-L1T2-OTV-FC active              Po11:SI1602
 0    1700 1700 *PR-ACH2-L1T2-OTV-FC active              Po11:SI1700
 0    1701 1701  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI1701
 0    1702 1702 *PR-ACH2-L1T2-OTV-FC active              Po11:SI1702
 0    1703 1703  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI1703
 0    1704 1704 *PR-ACH2-L1T2-OTV-FC active              Po11:SI1704
 0    1705 1705  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI1705
 0    1706 1706 *PR-ACH2-L1T2-OTV-FC active              Po11:SI1706
 0    1707 1707  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI1707
 0    1720 1720 *PR-ACH2-L1T2-OTV-FC active              Po11:SI1720
 0    1721 1721  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI1721
 0    1722 1722 *PR-ACH2-L1T2-OTV-FC active              Po11:SI1722
 0    1723 1723  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI1723
 0    1724 1724 *PR-ACH2-L1T2-OTV-FC active              Po11:SI1724
 0    1725 1725  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI1725
 0    1726 1726 *PR-ACH2-L1T2-OTV-FC active              Po11:SI1726
 0    1727 1727  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI1727
 0    1900 1900 *PR-ACH2-L1T2-OTV-FC active              Po11:SI1900
 0    1937 1937  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI1937
 0    1948 1948 *PR-ACH2-L1T2-OTV-FC active              Po11:SI1948
 0    2003 2003  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI2003
 0    2015 2015  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI2015
 0    2019 2019  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI2019
 0    2023 2023  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI2023
 0    2027 2027  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI2027
 0    2031 2031  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI2031
 0    2041 2041  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI2041
 0    2042 2042 *PR-ACH2-L1T2-OTV-FC active              Po11:SI2042
 0    2043 2043  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI2043
 0    2044 2044 *PR-ACH2-L1T2-OTV-FC active              Po11:SI2044
 0    2049 2049  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI2049
 0    2061 2061  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI2061
 0    2062 2062 *PR-ACH2-L1T2-OTV-FC active              Po11:SI2062
 0    2063 2063  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI2063
 0    2065 2065  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI2065
 0    2066 2066 *PR-ACH2-L1T2-OTV-FC active              Po11:SI2066
 0    2070 2070 *PR-ACH2-L1T2-OTV-FC active              Po11:SI2070
 0    2078 2078 *PR-ACH2-L1T2-OTV-FC active              Po11:SI2078
 0    2082 2082 *PR-ACH2-L1T2-OTV-FC active              Po11:SI2082
 0    2090 2090 *PR-ACH2-L1T2-OTV-FC active              Po11:SI2090
 0    2094 2094 *PR-ACH2-L1T2-OTV-FC active              Po11:SI2094
 0    2128 2128 *PR-ACH2-L1T2-OTV-FC active              Po11:SI2128
 0    2129 2129  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI2129
 0    2130 2130 *PR-ACH2-L1T2-OTV-FC active              Po11:SI2130
 0    2134 2134 *PR-ACH2-L1T2-OTV-FC active              Po11:SI2134
 0    2135 2135  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI2135
 0    2136 2136 *PR-ACH2-L1T2-OTV-FC active              Po11:SI2136
 0    2137 2137  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI2137
 0    2138 2138 *PR-ACH2-L1T2-OTV-FC active              Po11:SI2138
 0    2139 2139  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI2139
 0    2140 2140 *PR-ACH2-L1T2-OTV-FC active              Po11:SI2140
 0    2141 2141  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI2141
 0    2142 2142 *PR-ACH2-L1T2-OTV-FC active              Po11:SI2142
 0    2143 2143  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI2143
 0    2144 2144 *PR-ACH2-L1T2-OTV-FC active              Po11:SI2144
 0    2152 2152 *PR-ACH2-L1T2-OTV-FC active              Po11:SI2152
 0    2156 2156 *PR-ACH2-L1T2-OTV-FC active              Po11:SI2156
 0    2300 2300 *PR-ACH2-L1T2-OTV-FC active              Po11:SI2300
 0    2304 2304 *PR-ACH2-L1T2-OTV-FC active              Po11:SI2304
 0    2305 2305  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI2305
 0    2308 2308 *PR-ACH2-L1T2-OTV-FC active              Po11:SI2308
 0    2309 2309  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI2309
 0    2400 2400 *PR-ACH2-L1T2-OTV-FC active              Po11:SI2400
 0    2401 2401  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI2401
 0    2408 2408 *PR-ACH2-L1T2-OTV-FC active              Po11:SI2408
 0    2409 2409  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI2409
 0    2410 2410 *PR-ACH2-L1T2-OTV-FC active              Po11:SI2410
 0    2411 2411  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI2411
 0    2416 2416 *PR-ACH2-L1T2-OTV-FC active              Po11:SI2416
 0    2418 2418 *PR-ACH2-L1T2-OTV-FC active              Po11:SI2418
 0    2602 2602 *PR-ACH2-L1T2-OTV-FC active              Po11:SI2602
 0    2603 2603  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI2603
 0    2614 2614 *PR-ACH2-L1T2-OTV-FC active              Po11:SI2614
 0    3003 3003  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI3003
 0    3015 3015  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI3015
 0    3019 3019  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI3019
 0    3023 3023  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI3023
 0    3031 3031  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI3031
 0    3066 3066 *PR-ACH2-L1T2-OTV-FC active              Po11:SI3066
 0    3070 3070 *PR-ACH2-L1T2-OTV-FC active              Po11:SI3070
 0    3078 3078 *PR-ACH2-L1T2-OTV-FC active              Po11:SI3078
 0    3082 3082 *PR-ACH2-L1T2-OTV-FC active              Po11:SI3082
 0    3086 3086 *PR-ACH2-L1T2-OTV-FC active              Po11:SI3086
 0    3090 3090 *PR-ACH2-L1T2-OTV-FC active              Po11:SI3090
 0    3094 3094 *PR-ACH2-L1T2-OTV-FC active              Po11:SI3094
 0    3128 3128 *PR-ACH2-L1T2-OTV-FC active              Po11:SI3128
 0    3129 3129  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI3129
 0    3130 3130 *PR-ACH2-L1T2-OTV-FC active              Po11:SI3130
 0    3132 3132 *PR-ACH2-L1T2-OTV-FC active              Po11:SI3132
 0    3134 3134 *PR-ACH2-L1T2-OTV-FC active              Po11:SI3134
 0    3135 3135  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI3135
 0    3136 3136 *PR-ACH2-L1T2-OTV-FC active              Po11:SI3136
 0    3137 3137  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI3137
 0    3138 3138 *PR-ACH2-L1T2-OTV-FC active              Po11:SI3138
 0    3139 3139  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI3139
 0    3142 3142 *PR-ACH2-L1T2-OTV-FC active              Po11:SI3142
 0    3143 3143  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI3143
 0    3144 3144 *PR-ACH2-L1T2-OTV-FC active              Po11:SI3144
 0    3152 3152 *PR-ACH2-L1T2-OTV-FC active              Po11:SI3152
 0    3156 3156 *PR-ACH2-L1T2-OTV-FC active              Po11:SI3156
 0    3232 3232 *PR-ACH2-L1T2-OTV-FC active              Po11:SI3232
 0    3300 3300 *PR-ACH2-L1T2-OTV-FC active              Po11:SI3300
 0    3303 3303  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI3303
 0    3304 3304 *PR-ACH2-L1T2-OTV-FC active              Po11:SI3304
 0    3400 3400 *PR-ACH2-L1T2-OTV-FC active              Po11:SI3400
 0    3401 3401  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI3401
 0    3406 3406 *PR-ACH2-L1T2-OTV-FC active              Po11:SI3406
 0    3408 3408 *PR-ACH2-L1T2-OTV-FC active              Po11:SI3408
 0    3409 3409  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI3409
 0    3416 3416 *PR-ACH2-L1T2-OTV-FC active              Po11:SI3416
 0    3602 3602 *PR-ACH2-L1T2-OTV-FC active              Po11:SI3602
 0    3603 3603  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI3603
 0    3604 3604 *PR-ACH2-L1T2-OTV-FC active              Po11:SI3604
 0    3605 3605  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI3605
 0    4007 4007  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI4007
 0    4008 4008 *PR-ACH2-L1T2-OTV-FC active              Po11:SI4008
 0    4039 4039  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI4039
 0    4041 4041  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI4041
 0    4044 4044 *PR-ACH2-L1T2-OTV-FC active              Po11:SI4044
 0    4045 4045  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI4045
 0    4046 4046 *PR-ACH2-L1T2-OTV-FC active              Po11:SI4046
 0    4048 4048 *PR-ACH2-L1T2-OTV-FC active              Po11:SI4048
 0    4060 4060 *PR-ACH2-L1T2-OTV-FC active              Po11:SI4060
 0    4071 4071  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI4071
 0    4072 4072 *PR-ACH2-L1T2-OTV-FC active              Po11:SI4072
 0    4075 4075  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI4075
 0    4082 4082 *PR-ACH2-L1T2-OTV-FC active              Po11:SI4082
 0    4083 4083  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI4083
 0    4084 4084 *PR-ACH2-L1T2-OTV-FC active              Po11:SI4084
 0    4085 4085  PR-ACH3-L1T2-OTV-FC inactive(NA)        Po11:SI4085
```
