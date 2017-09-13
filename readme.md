# DocSearch

The InterSystems DBMS has a built-in technology for working with non-structured data called iKnow and a full-text search technology called iFind. We decided to take a dive into both and make something useful. As the result, we have DocSearch —  a web application for searching in InterSystems documentation using iKnow and iFind.

## Usage description and information about technologies

Read <a href="https://community.intersystems.com/post/search-intersystems-documentation-using-iknow-and-ifind-technologies">post on Developer Community</a>. <a href="https://habrahabr.ru/company/intersystems/blog/333582">Russian article on Habrahabr</a>

## Installation and Usage

Download the Installer.xml file from the latest release available on the corresponding page.
Import the loaded Installer.xml file into the %SYS namespace and compile it.
Enter the following command in the terminal in the %SYS namespace: 

do ##class(Docsearch.Installer).setup(.pVars)

The process takes around 15-30 minutes because of the domain builiding process.

After that, the search will be available at the following address
http://localhost:[port]/csp/docsearch/index.html


