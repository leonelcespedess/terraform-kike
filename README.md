# terraform-kike

Se levanta un backend para la EC2 con IP elastica, donde queda lista con el nginx implementado listo para subir los archivos que se necesiten.
Tambien se hizo una api gateway, donde tiene el ruteo de ruta-api/instancia lleva hacia el ip de la instancia EC2 levantada, donde se muestra el landing de nginx.
Tambien se hizo el front, donde debe estar en el repositorio un archivo /dist con un frontend, para subirlo como base. este tiene una distribucion clodufront asociada, por lo que se puede acceder al acceder al ID de el cloudfront creado.
PAra obtener los links hay que buscarlos directamente en el aws. (me olvide de poner los outpus para tener cada link)
