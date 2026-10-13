from pathlib import Path
root=Path('assets/gu/illustrated')
base='<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 100 100"><g stroke="#292e2b" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">'
end='</g></svg>\n'
icons={}
icons['moon']='''
<!-- Nguyet Quang: a living crescent-wing moth, not an abstract moon button. -->
<path d="M42 39 Q31 21 18 21 Q10 30 13 44 Q15 59 37 68 Q22 52 29 40 Q34 35 42 39Z" fill="#637e6c"/>
<path d="M58 39 Q69 21 82 21 Q90 30 87 44 Q85 59 63 68 Q78 52 71 40 Q66 35 58 39Z" fill="#abc2a0"/>
<path d="M43 46 Q26 42 20 29 Q18 52 37 63 Q26 48 43 46Z" fill="#aec5a6" stroke-width="1"/>
<path d="M57 46 Q74 42 80 29 Q82 52 63 63 Q74 48 57 46Z" fill="#e1dfae" stroke-width="1"/>
<path d="M43 50 Q29 57 26 71 Q37 74 46 62L50 52Z" fill="#92aa88"/>
<path d="M57 50 Q71 57 74 71 Q63 74 54 62L50 52Z" fill="#718e78"/>
<path d="M37 29Q39 37 42 41M65 29Q61 35 59 41M30 61L41 56M68 63L60 57" fill="none" stroke="#d8dab0" stroke-width="1.2"/>
<path d="M45 30Q36 26 37 16M55 30Q63 23 61 16" fill="none" stroke-width="1.7"/>
<path d="M43 34 Q45 26 50 27 Q58 28 57 35L54 43H46Z" fill="#d9d9ad"/>
<path d="M46 42Q40 51 46 68L50 81Q58 72 57 60L54 42Z" fill="#51675a"/>
<path d="M48 44Q50 41 52 45L52 72L49 75Z" fill="#c4d0a2" stroke-width=".9"/>
<path d="M45 54L55 54M46 62L54 62M48 69L52 69" fill="none" stroke-width="1.2"/>
<path d="M45 34L47 35M53 35L55 34" stroke="#292e2b" stroke-width="2.6"/>
<path d="M43 45L35 49M57 45L65 49" fill="none" stroke-width="1.5"/>
'''
icons['shield']='''
<!-- Bach Ngoc: articulated jade scarab with overlapping armor scales. -->
<path d="M34 40L24 32L18 35M33 50L19 47L14 53M35 64L22 68L20 77M66 40L76 32L82 35M67 50L81 47L86 53M65 64L78 68L80 77" fill="none" stroke="#a39671" stroke-width="5"/>
<path d="M34 40L24 32L18 35M33 50L19 47L14 53M35 64L22 68L20 77M66 40L76 32L82 35M67 50L81 47L86 53M65 64L78 68L80 77" fill="none" stroke-width="1.5"/>
<path d="M41 26L35 18L37 10Q41 13 44 19L50 23L56 19Q59 13 63 10L65 18L59 26" fill="#c5ba91"/>
<path d="M40 27Q50 18 60 27L61 36H39Z" fill="#698071"/>
<path d="M38 34Q50 28 62 34Q76 44 72 61Q68 78 50 87Q32 78 28 61Q24 44 38 34Z" fill="#a9b6a1"/>
<path d="M50 34Q64 35 69 47Q73 65 50 82Z" fill="#e0ddbd"/>
<path d="M50 34Q36 35 31 47Q27 65 50 82Z" fill="#acb9a0"/>
<path d="M50 38L50 80M31 50Q40 44 49 47M69 50Q60 44 51 47M34 65Q40 60 49 63M66 65Q60 60 51 63" fill="none" stroke="#657764" stroke-width="1.4"/>
<path d="M36 41Q34 44 33 48M61 41L64 46M61 71L54 78" fill="none" stroke="#f0e5c5" stroke-width="2.7"/>
<path d="M50 39L56 46L50 56L44 46Z" fill="#738a75"/>
<path d="M50 41L52 46L50 51" fill="none" stroke="#e8d9a8"/>
<path d="M41 28L44 29M56 29L59 28" stroke="#292e2b" stroke-width="2.7"/>
'''
icons['dash']='''
<!-- Bach Hac: crane-like spirit insect with long feathered wing silhouettes. -->
<path d="M45 47Q31 42 27 19Q22 30 26 42L17 29Q14 47 24 53L11 48Q18 64 39 62Z" fill="#aebcb0"/>
<path d="M55 47Q69 42 73 19Q78 30 74 42L83 29Q86 47 76 53L89 48Q82 64 61 62Z" fill="#e7e0c4"/>
<path d="M43 49Q34 42 30 30M41 54Q30 51 23 39M38 58Q29 57 20 53M57 49Q66 42 70 30M59 54Q70 51 77 39M62 58Q71 57 80 53" fill="none" stroke="#677f74" stroke-width="1.25"/>
<path d="M44 55L29 77L42 71L44 88L51 70L57 82L56 67L70 76L58 54Z" fill="#c2cbb7"/>
<path d="M47 40Q43 47 46 63L50 77Q56 66 56 56L54 40Z" fill="#617b70"/>
<path d="M50 43L50 70" fill="none" stroke="#ece4c4" stroke-width="2.7"/>
<path d="M45 38Q43 29 50 27Q57 29 55 38L53 43H47Z" fill="#e4dfc5"/>
<path d="M46 29Q39 22 39 17M54 29Q61 21 63 20" fill="none"/>
<path d="M47 34L48 35M52 35L53 34" stroke="#292e2b" stroke-width="2.6"/>
<path d="M40 63L33 68M60 63L67 68" fill="none"/>
<path d="M18 70L11 75M23 76L18 81M80 70L86 72" fill="none" stroke="#9dac9b" stroke-width="1.4"/>
'''
icons['frost']='''
<!-- Bang Tam: curled silkworm, crystal horn and silk filament. -->
<path d="M19 66Q21 37 46 29L77 32Q68 39 70 48Q56 49 42 72L27 79Z" fill="#536f66"/>
<path d="M25 72Q48 43 72 34M32 64L28 50M44 51L43 39M42 56L54 57" fill="none" stroke="#99b3a3" stroke-width="1.2"/>
<path d="M68 46Q81 53 76 67Q71 82 52 79Q31 78 33 58Q34 44 46 40L55 43Q41 48 43 59Q45 69 55 68Q65 68 63 58Z" fill="#a4baba"/>
<path d="M45 43Q48 47 48 51M37 51Q42 51 44 55M35 61Q40 60 44 62M39 70Q43 66 47 66M48 76Q49 72 52 68M60 77L59 69M70 72L65 66M75 63L67 61" fill="none" stroke="#526c68" stroke-width="1.7"/>
<path d="M42 48Q47 44 51 45M39 56L40 60M46 71L49 72M59 73L63 71" fill="none" stroke="#e3e4d0" stroke-width="2.2"/>
<path d="M58 53Q50 45 53 35Q58 24 69 27Q81 30 80 43Q78 55 67 57Z" fill="#d7ddd0"/>
<path d="M59 30L59 18L67 25L72 16L73 29" fill="#9ebbc2"/>
<path d="M63 42L66 44M74 39L76 40" stroke="#2c3d39" stroke-width="2.8"/>
<path d="M65 50Q70 52 73 47" fill="none" stroke-width="1.2"/>
<path d="M78 47Q89 51 83 61Q77 69 86 80" fill="none" stroke="#d7dfc8" stroke-width="1.3"/>
<path d="M22 39L21 27L28 35L29 44Z" fill="#a3c5c3"/>
<path d="M78 20L84 14L86 22L82 28Z" fill="#c2d7ce" stroke-width="1.3"/>
'''
for kind,body in icons.items(): (root/(kind+'.svg')).write_text(base+body+end)
