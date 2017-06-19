ROUTINE DocBookMac [Type=INC]

#;
#; Default message macro
#; 
#; This macro sits on top of the $$$Text macro so that we can
#; supply the default locale, "DocBook"
#;
#; This is used instead of specifying a LOCALE parameter in each class
#; because of the possibility of sub-classing by users in the field.
#;
#; The Text macro is in %occMessages.inc in the %SYS database.  It must
#; be included with this and cannot be included from this macro.
#;
#define T(%text) $$$Text(%text,"DOCBOOK") 
#define TH(%text) $$$TextHTML(%text,"DOCBOOK") 
#define TJ(%text) $$$TextJS(%text,"DOCBOOK") 

#; Maximum number of items to display per topic
#define ITEMSPERTOPIC $G(^SearchConfig("itemspertopic"),9)
#; Maximum number of items to display per page of results
#define ITEMSPERPAGE $G(^SearchConfig("itemsperpage"),20)
#; Minimum number of characters needed to display a result
#define MINCHARPERRESULT $G(^SearchConfig("mincharperresult"),1)


