<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"
	import="nl.geozet.common.CoreResources,nl.geozet.common.StringConstants"%>
<%
	    CoreResources RESOURCES = new CoreResources(this
	            .getServletContext().getInitParameter(
	                    StringConstants.CONFIG_PARAM_RESOURCENAME.code));
%>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="nl" lang="nl">
<head>

        <meta http-equiv="Content-Type" content="application/xhtml+xml; charset=utf-8" />
		<title>Overheid.nl | Over uw buurt - Gebied attenderingsservice</title>
        <%--jsp:include page="WEB-INF/overheidnl-head.jsp" /--%>

	<link rel="stylesheet" href="static/css/style.css" type="text/css" media="all" />
	

	<!--[if lte IE 7]>
		<link rel="stylesheet" href="static/css/ie.css" type="text/css" media="all" />
	<![endif]-->
	<!--[if gte IE 8]>
		<link rel="stylesheet" href="static/css/ie-8.css" type="text/css" media="all" />
	<![endif]-->

	<link rel="stylesheet" href="static/css/print.css" type="text/css" media="print" />

	<script type="text/javascript">
		document.documentElement.className += ' js';
	</script>

</head>
<body class="font-medium">
<%--jsp:include page="WEB-INF/overheidnl-header.jsp" /--%>
<h1 class="popupMap">Uw selectie</h1>
<p id="kaarttoelichting"></p>

<%@ include file="WEB-INF/corecheck.jsp" %>
<div id="geozetContent" class="start flexibleSize">
	
		<div id="geozetArticle">

			<div id="geozetCore">
           	
				<jsp:include page="WEB-INF/zoekformulier.jsp" />

			</div>
			
			<div id="geozetEnhanced" class="hidden">
				<div id="geozetMap"></div>
			</div>
		</div>

		<div id="geozetAside">

<%-- jsp:include page="WEB-INF/overheidnl-zoeken.jsp" / --%>

			<div id="geozetAsideCore"></div>
			
			<div id="geozetAsideEnhanced">
			
			</div>

		</div>
</div>

<%--jsp:include page="WEB-INF/overheidnl-footer.jsp" /--%>

</body>
</html>