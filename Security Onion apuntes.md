+ Pasamos a *ungroup view* para poder ver los timestamps
+ Empezamos por la alerta:
	`ET HUNTING SUSPICIOUS Possible Office Doc with Embedded VBA Project (Wide)`
+ En la vista detallada, podemos ver el `network.data.decoded` pero tenemos que tener en cuenta que no estamos viendo el flujo TCP completo
	+ Aquí sólo vemos el `200 OK` pero no lo que el cliente web envió antes
	+ Para verlo completo, `click encima > action > PCAP`
	 ![[Pasted image 20230227134008.png]]
+ Podemos ver que todo empieza con esta petición al servidor que devuelve un Excel:
	`GET /wp-content/Receipt-9650354.xls?evagk=2MyeEdhGPszYX`
+ Volvemos para atrás en las alertas y ahora nos fijamos en las alertas:
	1. `ET POLICY PE EXE or DLL Windows file download HTTP`
	2. `ET INFO EXE IsDebuggerPresent (Used in Malware Anti-Debugging)`
	Y vemos que ambas comparten el mismo puerto destino, **59381**
+ Mirando los timestamps, vemos que después de descargarse la Excel, sólo unos segundos después, se suceden estas dos alertas
+ En la primera alerta, `click encima > action > PCAP`
+ ![[Pasted image 20230304231505.png]]
+ Se está haciendo un request de un .bin, a una web extraña y desde un user-agent aún más extraño. 
+ En la respuesta vemos el string *MZ* que esl magic number [que identifica al archivo como un *.exe*](https://en.wikipedia.org/wiki/DOS_MZ_executable)
+ Podríamos extraer el *.exe* del PCAP y estudiarlo, pero vamos a usar Cyberchef:
![[Pasted image 20230304232041.png]]

+ Una vez en Cyberchef podemos y debemos:
	+ `Strip HTTP headers` para quitarle las cabeceras
	+ Tras esto, si ponemos el cursor encima de la varita mágica del *Output* nos da que si volvemos quitar las cabeceras, nos aparecerá el archivo MZ, así que pulsaremos y nos dará el archivo en crudo
		![[Pasted image 20230305174305.png]]
	 + Podríamos guardar el archivo con el  icono de guardar, con el fin de correrlo en un sandbox
+ O también podemos utilizar **strings** sobre él simplemente:
![[Pasted image 20230305174615.png]]
+ Tras ello vemos cosas interesantes como:
	+ Llamadas a un programa llamado testapp.exe
	+ Referencias a un par de DLL's
	+ Llamadas a la API de Windows
+ Volvemos a atrás desde el PCAP y le echamos un ojo a las alertas que siguen a las anteriores
	+ Vemos que hay un tráfico constante y muy seguido en los números de puerto origen, destinado al puerto **443** y que avisa de ***Possible Dridex***
	+ Si buscamos, vemos que Dridex es un malware conocido: https://www.checkpoint.com/cyber-hub/threat-prevention/what-is-malware/what-is-dridex-malware/

+ Hay indicios bastante claros, sin embargo, como Blue teamers debemos considerar que los adversarios van a utilizar técnicas realmente sofisticadas para evadir y engañar a nuestros sistemas.
	+ Esta es la información que nos proporciona nuestro IDS pero pueden estar pasando cosas en background que no estemos viendo
	+ Debemos hacer uso de toda la tecnología y herramientas a nuestro alcance, recopilando tantos metadatos como nos sea posible para estudiar el caso y poder mirar la información desde otro ángulo, con el fin de detectar todas las anomalías y averiguar que está pasando realmente
+ Para hacer esto, nos vamos  `Hunt` y utilizamos la query predefinida `* | groupby event.module event.dataset` del botón de drop-down (Recordar poner periodo de los últimos 24 meses)
	 1. Lo primero que vemos es que tenemos unas cuántas alertas de **Suricata**
	 2. Pero también tenemos un montón de logs de **Zeek**, que incluyen:
		 + Connection log
		 + Dns log
		 + Ssl log
 + Esto nos proporciona una visión a alto nivel de los diferentes tipos de datos que tenemos en nuestra mano y nos da una idea de hacia donde continuar y qué mirar
 + Miremos el connection log:
	 + Del menú drop-down, tenemos un montón de queries predefinidas para el Connection log
	 + Podemos echar un ojo a las conexiones agrupadas por servicio:
			`event.dataset:conn | groupby network.protocol destination.port`
 + Una vez más, tenemos una visión a alto nivel de todas las conexiones que ha "visto" Zeek y agrupadas por protocolos que Zeek ha sido capaz de identificar 
 + Viendo los puertos de destino empezamos a ver "cosas raras":
	 + ¿Tráfico SSL en el puerto 453 en lugar del 443?
	 + ¿Tráfico HTTP en el puerto 8088? --> Había una alerta del IDS anterior con este puerto pero si no la hubiera, así es como lo hubiéramos visto
+ Otra cosa interesante que podemos hacer es ver todas aquellas conexiones donde Zeek no ha sido capaz de identificar el protocolo
	+ Para ello, en la query, añadimos un asterisco detrás de `protocol`
+ Vemos un montón de *Missing*
	+ Echemos un vistazo al missing del puerto 443
		+ Click encima del puerto y en el menú --> Include
		+ Y nos deja ver todo el tráfico del puerto 443:
![[Pasted image 20230305185222.png]]
+ Excluimos el tráfico SSL (botón izdo sobre SSL y en el menú, Exclude) y nos quedamos sólo con el missing:
![[Pasted image 20230305194809.png]]

+ En la parte de abajo vemos a qué IPs de Internet se está conectando ese host comprometido
	+ Cogemos la conexión de las 01:47:51 y le decimos ver el PCAP
![[Pasted image 20230305214415.png]]

+ Vemos que hay unos carácteres extraños que pueden ser la causa por la que  Zeek no ha podido identificarlo como un protocolo conocido
+ Una vez llegamos a la parte que sí parece ser estándar HTTP, vemos una petición GET a C:/Users y un 200 OK por respuesta
+ Mandamos esto a Cyberchef:
	+ Strip HTTP headers
	+ Magic
	+ Guardamos el archivo como `salida.html`
+ Lo abrimos y vemos que es un listado del directorio
+ Hacemos lo propio con las dos conexiones siguientes
