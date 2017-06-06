<%@ page import = "java.io.*" %>
<%@ page import = "java.net.URL" %>
<%@ page import = "java.net.URLEncoder" %>
<%@ page import = "java.net.URLConnection" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.awt.Color" %>
<%@ page import = "java.awt.Graphics2D" %>
<%@ page import = "java.awt.RenderingHints" %>
<%@ page import = "java.awt.Stroke" %>
<%@ page import = "java.awt.BasicStroke" %>
<%@ page import = "javax.imageio.*" %>
<%@ page import = "javax.xml.parsers.DocumentBuilder" %>
<%@ page import = "javax.xml.parsers.DocumentBuilderFactory" %>
<%@ page import = "org.w3c.dom.Document" %>
<%@ page import = "org.w3c.dom.*" %>
<%@ page import = "java.awt.image.BufferedImage" %>
<%@ page import = "nl.geozet.openls.client.*" %>
<%@ page import = "nl.geozet.openls.databinding.openls.*" %>
<%@ page contentType="image/png" trimDirectiveWhitespaces="true"%><%

    /* ----------------
     *   start config 
    ---------------- */
    // gemeenteServiceHost points to the server that offers a WFS and WMS with gemeente borders, used to display the borders on the image
    /* Assumptions for now:
    1. the WMS and WFS run on the same machine (which is the case for Geoserver used in this application) and use URLs following this pattern:
        http(s)://{gemeenteServiceHost}/wms
        http(s)://{gemeenteServiceHost}/wfs
    2.  The scheme, like http or https is *always* the same as the one of the request
    
    Set gemeenteServiceHost to a servername (and optionally port) to specifiy another host than the hostname and port of the request. If gemeenteServiceHost is set to "", the same host and port are used as the ones of the request. This last option seems to be the best for the current environment of overuwbuurt.
    For example: 
        gemeenteServiceHost = "46.4.119.75"; --> {scheme}://46.4.119.75/wms and {scheme}://46.4.119.75/wfs
        gemeenteServiceHost = "localhost:8080"; --> {scheme}://localhost:8080/wms and {scheme}://localhost:8080/wfs
        gemeenteServiceHost = ""; --> {scheme}://{servername}:{port}/wms and {scheme}://{servername}:{port}/wfs
    */
    String gemeenteServiceHost = "";

    // the WFS/WMS featuretype/layername and property containing the names of the gemeente to filter on. I.e.: this property is used to find the gemeente name in that is returned from the Geocoder.
    String gemeenteLayerName = "geozet:gemeentegrenzen";
    String filterPropertyName = "gemeentenaam";
    
    String openLSUrl = "http://geodata.nationaalgeoregister.nl/geocoder/Geocoder";

    // A WMS url for the basemap
    // NOTES: width, height and bbox are added later.
    // provide the rest of the WMS URL here
    // Assume a PNG image
    String baseUrlBasemap = "http://www.openbasiskaart.nl/mapcache/?service=WMS&request=GetMap&VERSION=1.1.1&layers=osm&transparent=TRUE&format=image/png&srs=EPSG:28992";
    /* ----------------
     *  end config 
    ---------------- */

    // Now construct the host machine
	String baseHost = "";
    // Thijs Brentjens (2014-09-11), force http. Was: request.getScheme(), but now we force the scheme http:// because of a certificate error in the overheid.nl certificate that causes rrors in creating the connection using commons-httpclient
    // Wouter de Groot (2015-07-01), removed:  + ":" + request.getServerPort(), made an if statement for http:// or https://
    Integer serverPort = request.getServerPort();
    if (serverPort==443) {
    baseHost = "https://" + request.getServerName();
    } 
    else {
    baseHost = "http://" + request.getServerName();
    } 
    if (gemeenteServiceHost.length() > 0) { // should be at least a few characters
        // force schem http://
        baseHost = "http://" + gemeenteServiceHost;
    }


    String baseUrlGemeenteWMS = baseHost+ "/wms";
    String baseUrlGemeenteWFS = baseHost+ "/wfs";   

    OutputStream o = response.getOutputStream();

    Integer adresstraal = -1;
    String gemeentenaam = "";
    // if straal is -1, then we have to use a gemeente
    if (request.getParameter("adresstraal") != null) {
        adresstraal = Integer.parseInt(request.getParameter("adresstraal"));
    }

    // -1 means: automatically, using a 50% margin around the adresstraal
    Integer kaartstraal = -1;
    if (request.getParameter("kaartstraal") != null) {
        kaartstraal = Integer.parseInt(request.getParameter("kaartstraal"));
    } else {
        kaartstraal = ((Double)( 1.5 * adresstraal)).intValue();
    }

    String adres = "";
    if (request.getParameter("adres") != null) {
        adres = request.getParameter("adres");
      
        Integer afbeeldingsgrootte = 500;
        if (request.getParameter("afbeeldingsgrootte") != null) {
            afbeeldingsgrootte = Integer.parseInt(request.getParameter("afbeeldingsgrootte"));
        }
        // TODO: choose WMS and configure
        // For now: use openbasiskaart
        baseUrlBasemap = baseUrlBasemap +"&width="+afbeeldingsgrootte+"&height="+afbeeldingsgrootte+"&bbox=";

        // Configure: make sure to set the host of the WMS url for geozet's server above!
        String gemeenteWMSUrl = "";
        String gemeenteWFSURL = baseUrlGemeenteWFS + "?service=WFS&version=2.0.0&request=GetFeature&typename="+gemeenteLayerName; //+"&propertyname="+filterPropertyName; // filter property

        // get Address
        OpenLSClient ols = new OpenLSClient();
        final Map<String, String> openLSParams = new TreeMap<String, String>();

        // TODO: configuration, share from other servlets of Geozet
        // openLSParams.put(OPENLS_REQ_PARAM_SEARCH.code, zoekAdres);
        openLSParams.put("zoekterm", adres);
        
        Double x = 10000.0;
        Double y = 400000.0;

        final GeocodeResponse gcr;
        gcr = ols.doGetOpenLSRequest(openLSUrl, openLSParams);
        final List<OpenLSClientAddress> addrl = OpenLSClientUtil
                .getOpenLSClientAddressList(gcr);

        URL mapImageUrl;        

        String bbox;
        BufferedImage mapimage;
        BufferedImage gemeenteImage = null;
        
        if (addrl.size() > 0) {
            // assume only one match, which should be save if postalcodes and optionally house numbers are used
            final OpenLSClientAddress addr = addrl.get(0);
            x = Double.parseDouble(addr.getxCoord());
            y = Double.parseDouble(addr.getyCoord());

            // If the straal is "-1" then we don't draw a cricle, but the municipality where the provided address (postalcode + house number) is part of
            // try to find the municipality address from the geocoded results
            if (adresstraal==-1) {
                gemeentenaam = addr.getMunicipality();

                // try to get the boundaries of the municipality by requesting a WFS
                // The parsing of the WFS result is not very good at the moment, but works..

                // ---------------------
                // Fixes for differences in names of municipalitities and PDOK gemeentenaam-attribute:

                // 1) deal with "." in a municipality name, e.g.:                
                // Bergen (L.) --> Bergen (L)
                // So remove the "."

                gemeentenaam = gemeentenaam.replace(".)", ")");

                // 2) Hengelo --> Hengelo (O), an exception..
                if (gemeentenaam.equals( "Hengelo")) {
                    gemeentenaam = "Hengelo (O)";
                }

                // end fixes for names
                // ---------------------

                // CQL filters: encode single quotes by adding an extra one!
                gemeentenaam = gemeentenaam.replace("'", "''");

                // We need URL encoding using ISO-8859-1 because of Frysian names
                gemeentenaam = URLEncoder.encode(gemeentenaam, "ISO-8859-1");

                String cql_filter = "&cql_filter="+filterPropertyName+"%3D%27"+gemeentenaam+"%27";

                // could use an XML filter as well, but CQL_FILTER is easier
                // String xml_filter_encoded = "&filter=%3Cfes%3AFilter%20xmlns%3Afes%3D%27http%3A%2F%2Fwww.opengis.net%2Ffes%2F2.0%27%3E%3Cfes%3APropertyIsEqualTo%3E%20%20%3Cfes%3APropertyName%3E"+filterPropertyName+"%3C%2Ffes%3APropertyName%3E%3Cfes%3ALiteral%3E"+gemeentenaam+"%3C%2Ffes%3ALiteral%3E%3C%2Ffes%3APropertyIsEqualTo%3E%3C%2Ffes%3AFilter%3E";
                
                URL wfsReq = new URL(gemeenteWFSURL+cql_filter);
                URLConnection connection = wfsReq.openConnection();
                DocumentBuilder parser = DocumentBuilderFactory.newInstance().newDocumentBuilder();

                Document document = parser.parse(connection.getInputStream());
                // TODO: how to deal with logging??
                // TODO: what if the feature is not found? How to get the area then?

                // TODO: update all municipality data in the WFS from PDOK? Proxy the WFS data? --> use an external WFS source
                // TODO: document this. Or use the WFS of bestuurlijke grenzen directly? --> no external source is needed for WMS image and styling.

                // Try to get the boundingbox
                // TODO: this should be more robuste parsing of the XML probably / more generic in GML, but it works for now for this way of GML encoding.
                // Try to find the names of the element as well
                // TODO: decide what to do if the bbox is not found

                String lowerCornerString = "";
                String upperCornerString = "";

                if( document.getDocumentElement().getFirstChild().getFirstChild().getChildNodes().item(0).hasChildNodes()) {
                    lowerCornerString = document.getDocumentElement().getFirstChild().getFirstChild().getChildNodes().item(0).getFirstChild().getNodeValue();
                }
                if( document.getDocumentElement().getFirstChild().getFirstChild().getChildNodes().item(1).hasChildNodes()) {
                    upperCornerString = document.getDocumentElement().getFirstChild().getFirstChild().getChildNodes().item(1).getFirstChild().getNodeValue();
                }
				
                // Set the x and y as the center of the image, calculate the new bbox by getting the x and y diff, the biggest axis and use a margin around it

                // first: parse the coords:
                Double minX = Double.parseDouble(lowerCornerString.split(" ")[0]);
                Double minY = Double.parseDouble(lowerCornerString.split(" ")[1]);

                Double maxX = Double.parseDouble(upperCornerString.split(" ")[0]);
                Double maxY = Double.parseDouble(upperCornerString.split(" ")[1]);

                Double dX = maxX - minX;
                Double dY = maxY - minY;

                Double dBbox = (Math.max(dX, dY) * 0.5)*1.1; // + add a margin of 10%

                Double centerX = dX * 0.5 + minX;
                Double centerY = dY * 0.5 + minY;

                bbox = "" + (centerX - dBbox) + "," + (centerY - dBbox) + "," + (centerX + dBbox) + "," + (centerY + dBbox) ; // try to create a string...

                gemeenteWMSUrl = baseUrlGemeenteWMS+"?service=WMS&version=1.1.1&request=GetMap&layers="+gemeenteLayerName+"&styles=&width="+afbeeldingsgrootte+"&height="+afbeeldingsgrootte+"&transparent=TRUE&srs=EPSG:28992&format=image/png&bbox=";
                // add the bbox

                gemeenteWMSUrl = gemeenteWMSUrl + bbox;
                // and add the gm_naam parameter:

                gemeenteWMSUrl = gemeenteWMSUrl + cql_filter; // cql_filter;

                // TODO: handle exceptions. What if the municipalty is not found for example?
                gemeenteImage = ImageIO.read(new URL(gemeenteWMSUrl));
            }
            else {
                bbox = (x-kaartstraal)+","+(y-kaartstraal)+","+(x+kaartstraal)+","+(y+kaartstraal);
            }

            mapImageUrl = 
              new URL(baseUrlBasemap+bbox);
            mapimage = ImageIO.read(mapImageUrl);

            // now, draw on the image some circles
            Graphics2D g2d = mapimage.createGraphics();
            g2d.setRenderingHint (RenderingHints.KEY_ANTIALIASING,   RenderingHints.VALUE_ANTIALIAS_ON);

            if (gemeenteImage!=null ) {
                g2d.drawImage(gemeenteImage, 0, 0, null);
            }             
            // draw a circle around the address if a specific address is requested
            // if boundaries f the municiaplity are requested, only draw the gemeenteimage
            else if (adresstraal!=-1) {
                // center?
                Integer imageCentre = Math.round(afbeeldingsgrootte / 2);
                Integer tekenStraal = Math.round(new Float(afbeeldingsgrootte) * new Float(adresstraal) / new Float(kaartstraal));

                // the center marker
                Integer markerSize = 10;
                g2d.setPaint(new Color(255,0,0));

                g2d.fillOval(imageCentre - markerSize / 2, imageCentre - markerSize / 2, markerSize, markerSize);

                // TODO: color config: through web.xml or URL params?
                // alpha transparency
                g2d.setPaint(new Color(255,138,0,96));

                // startpos: imageCentre - adresstraal (in meters!)
                g2d.fillOval(imageCentre - tekenStraal / 2, imageCentre - tekenStraal / 2, tekenStraal, tekenStraal);

                // TODO: configuration of the colors. Through URL params?
                g2d.setPaint(new Color(255,138,0,220));
                Stroke stroke = new BasicStroke(2);
                g2d.setStroke(stroke);
                g2d.drawOval(imageCentre - tekenStraal / 2, imageCentre - tekenStraal / 2, tekenStraal, tekenStraal);
            }
            g2d.dispose();
        } else {
            // TODO: error? Blank image?
            bbox = (x-kaartstraal)+","+(y-kaartstraal)+","+(x+kaartstraal)+","+(y+kaartstraal);
            mapImageUrl = new URL(baseUrlBasemap+bbox);
            
            mapimage = ImageIO.read(mapImageUrl);

            // TODO: install fonts?
            // Graphics2D g2d = mapimage.createGraphics();
            // g2d.setRenderingHint (RenderingHints.KEY_ANTIALIASING,   RenderingHints.VALUE_ANTIALIAS_ON);
            // g2d.setPaint(Color.black);
            // String errorMsg = "Geen gemeente gevonden voor het opgegeven adres: " + adres;
            // g2d.drawString(errorMsg, 50, 50);
        }
        ImageIO.write(mapimage, "png", o);
        o.flush();
        o.close();// *important* to ensure no more jsp output
        return; 
    }
    else {
        // error
        o.flush();
        o.close();// *important* to ensure no more jsp output
        return; 
    }
%>