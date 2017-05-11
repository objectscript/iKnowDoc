Class REST.Router extends %CSP.REST {


Parameter UseSession As Integer = 1;

/// Карта путей REST web API
XData UrlMap
{

<Routes>	
	<Route Url="/GetSimilar/:text" Method="GET" Call="Search.Domain:GetSimilar"/>
	<Route Url="/Search" Method="POST" Call="Search.SearchPages:Search"/>
</Routes>
}


}