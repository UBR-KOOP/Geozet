package nl.geozet.wfs;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.log4j.Logger;

import nl.geozet.GeozetServlet;

import static nl.geozet.common.StringConstants.CONFIG_PARAM_WFS_CAPABILITIES_URL;

/**
 * Servlet implementation class BekendmakingXML
 *
 * Deze servlet haalt een WFS request op en zorgt dat de XML tags voor <geozet:adres> goed worden gezet.
 * 
 * @author Rob van Loon (Ordina)
 * @since 1.3.8
 *
 */
public class BekendmakingXML extends HttpServlet {
	
	/** Generated versionID	 */
	private static final long serialVersionUID = 1L;
	
    /** log4j logger. */
    private static final Logger LOGGER = Logger.getLogger(GeozetServlet.class);
       
    /**
     * @see HttpServlet#HttpServlet()
     */
    public BekendmakingXML() {
        super();
    }

	/**
	 * Maak een WFS-request en verbeter de xml-tags voor <geozet:adres>
	 * 
	 * @see HttpServlet#doGet(HttpServletRequest request, HttpServletResponse response)
	 */
	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		//TODO: enkel XML ondersteuning afdwingen
		
		String url = this.getServletContext().getInitParameter(CONFIG_PARAM_WFS_CAPABILITIES_URL.code);
		url = url.substring(0, url.length()-"request=GetCapabilities&version=1.1.0".length());
		url += request.getQueryString();
		if (url.contains("bekendmakingen_vlak")){
			url += "&propertyname=(oid,categorie,onderwerp,titel,beschrijving,url,datum,overheid,oppervlak,adres)";
		}
		url += "&service=wfs&version=1.1.0";
		LOGGER.debug("URL met query naar WFS: " + url);
		URL wfsURL = new URL(url);

		String out = getWFS(wfsURL);

		response.setCharacterEncoding("UTF-8");
		response.setContentType("application/xml; charset=UTF-8");
		response.getWriter().append(out);
	}
	
	/**
	 * Haal de inhoud van de WFS met URL op en output naar string.
	 * 
	 * @param url de url met het get-request voor de wfs
	 * @return string met de inhoud van het xml document
	 * @throws IOException IOException als de wfs van geoserver niet goed bereikt kan worden 
	 * @throws ServletException 
	 */
	private String getWFS(URL url) throws IOException, ServletException{
		
		HttpURLConnection con = (HttpURLConnection) url.openConnection();
		con.setRequestMethod("GET");

		BufferedReader in = null;
		String inputLine = null;
		StringBuilder wfsResponse = new StringBuilder();
		
		try { 
			in = new BufferedReader(new InputStreamReader(con.getInputStream(),"UTF-8"));
		
			while ((inputLine = in.readLine()) != null) {
				//waarschijnlijk is het 1 regel, maar voor de goede orde in de while loop gezet
				wfsResponse.append(inputLine);
			}
			
		} catch(IOException ex){
			LOGGER.error("IO Problemen met een WFS request", ex);
            throw new ServletException("De WFS-server is niet goed bereikbaar.",ex);
			
		} finally {
			in.close();
		}
		
		String out = parseXML(wfsResponse.toString());
		
		return out;
	}
	
	/**
	 * Bewerkt de input xml door de tags voor <geozet:adres> per blok te genereren.
	 * 
	 * De functie zet ook de <, > en : tekens terug die kwijt zijn geraakt bij het parsen van xml naar string.
	 * 
	 * @param input De XMLstream als string.
	 * @return bewerkte XML string met bijgewerkte tags voor <geozet:adres>
	 */
	private String parseXML(String input){
		String out = input;
		LOGGER.trace("in parseXML");
		LOGGER.trace(out);

		//De huidige <geozet:adres> wegkappen en terugzetten voor elke entry
		out = org.apache.commons.lang.StringUtils.replace(out, "<geozet:adres>", "");
		out = org.apache.commons.lang.StringUtils.replace(out, "</geozet:adres>", "");
		out = org.apache.commons.lang.StringUtils.replace(out, "&lt;geozet_x003A_postcodeHuisnummer&gt;", "<geozet:adres><geozet:postcodeHuisnummer>");
		out = org.apache.commons.lang.StringUtils.replace(out, "&lt;/geozet_x003A_postcodeHuisnummer&gt;", "</geozet:postcodeHuisnummer></geozet:adres>");
		out = org.apache.commons.lang.StringUtils.replace(out, "&lt;geozet_x003A_woonplaatsAdres&gt;", "<geozet:adres><geozet:woonplaatsAdres>");
		out = org.apache.commons.lang.StringUtils.replace(out, "&lt;/geozet_x003A_woonplaatsAdres&gt;", "</geozet:woonplaatsAdres></geozet:adres>");
		out = org.apache.commons.lang.StringUtils.replace(out, "&lt;geozet_x003A_gemeente&gt;", "<geozet:adres><geozet:gemeente>");
		out = org.apache.commons.lang.StringUtils.replace(out, "&lt;/geozet_x003A_gemeente&gt;", "</geozet:gemeente></geozet:adres>");
		out = org.apache.commons.lang.StringUtils.replace(out, "&lt;geozet_x003A_provincie&gt;", "<geozet:adres><geozet:provincie>");
		out = org.apache.commons.lang.StringUtils.replace(out, "&lt;/geozet_x003A_provincie&gt;", "</geozet:provincie></geozet:adres>");
		out = org.apache.commons.lang.StringUtils.replace(out, "&lt;geozet_x003A_waterschap&gt;", "<geozet:adres><geozet:waterschap>");
		out = org.apache.commons.lang.StringUtils.replace(out, "&lt;/geozet_x003A_waterschap&gt;", "</geozet:waterschap></geozet:adres>");
		out = org.apache.commons.lang.StringUtils.replace(out, "&lt;geozet_x003A_coordinaat&gt;", "<geozet:adres><geozet:coordinaat>");
		out = org.apache.commons.lang.StringUtils.replace(out, "&lt;/geozet_x003A_coordinaat&gt;", "</geozet:coordinaat></geozet:adres>");
		//
		out = org.apache.commons.lang.StringUtils.replace(out, "&lt;geozet:postcodeHuisnummer&gt;", "<geozet:adres><geozet:postcodeHuisnummer>");
		out = org.apache.commons.lang.StringUtils.replace(out, "&lt;/geozet:postcodeHuisnummer&gt;", "</geozet:postcodeHuisnummer></geozet:adres>");
		out = org.apache.commons.lang.StringUtils.replace(out, "&lt;geozet:woonplaatsAdres&gt;", "<geozet:adres><geozet:woonplaatsAdres>");
		out = org.apache.commons.lang.StringUtils.replace(out, "&lt;/geozet:woonplaatsAdres&gt;", "</geozet:woonplaatsAdres></geozet:adres>");
		out = org.apache.commons.lang.StringUtils.replace(out, "&lt;geozet:gemeente&gt;", "<geozet:adres><geozet:gemeente>");
		out = org.apache.commons.lang.StringUtils.replace(out, "&lt;/geozet:gemeente&gt;", "</geozet:gemeente></geozet:adres>");
		out = org.apache.commons.lang.StringUtils.replace(out, "&lt;geozet:provincie&gt;", "<geozet:adres><geozet:provincie>");
		out = org.apache.commons.lang.StringUtils.replace(out, "&lt;/geozet:provincie&gt;", "</geozet:provincie></geozet:adres>");
		out = org.apache.commons.lang.StringUtils.replace(out, "&lt;geozet:waterschap&gt;", "<geozet:adres><geozet:waterschap>");
		out = org.apache.commons.lang.StringUtils.replace(out, "&lt;/geozet:waterschap&gt;", "</geozet:waterschap></geozet:adres>");
		out = org.apache.commons.lang.StringUtils.replace(out, "&lt;geozet:coordinaat&gt;", "<geozet:adres><geozet:coordinaat>");
		out = org.apache.commons.lang.StringUtils.replace(out, "&lt;/geozet:coordinaat&gt;", "</geozet:coordinaat></geozet:adres>");
		//
		out = org.apache.commons.lang.StringUtils.replace(out, "&lt;geozet:postcode&gt;", "<geozet:postcode>");
		out = org.apache.commons.lang.StringUtils.replace(out, "&lt;/geozet:postcode&gt;", "</geozet:postcode>");
		out = org.apache.commons.lang.StringUtils.replace(out, "&lt;geozet:huisnummer&gt;", "<geozet:huisnummer>");
		out = org.apache.commons.lang.StringUtils.replace(out, "&lt;/geozet:huisnummer&gt;", "</geozet:huisnummer>");
		out = org.apache.commons.lang.StringUtils.replace(out, "&lt;geozet:huisnummertoevoeging&gt;", "<geozet:huisnummertoevoeging>");
		out = org.apache.commons.lang.StringUtils.replace(out, "&lt;/geozet:huisnummertoevoeging&gt;", "</geozet:huisnummertoevoeging>");
		out = org.apache.commons.lang.StringUtils.replace(out, "&lt;geozet:huisletter&gt;", "<geozet:huisletter>");
		out = org.apache.commons.lang.StringUtils.replace(out, "&lt;/geozet:huisletter&gt;", "</geozet:huisletter>");
		out = org.apache.commons.lang.StringUtils.replace(out, "&lt;geozet:straat&gt;", "<geozet:straat>");
		out = org.apache.commons.lang.StringUtils.replace(out, "&lt;/geozet:straat&gt;", "</geozet:straat>");
		out = org.apache.commons.lang.StringUtils.replace(out, "&lt;geozet:woonplaats&gt;", "<geozet:woonplaats>");
		out = org.apache.commons.lang.StringUtils.replace(out, "&lt;/geozet:woonplaats&gt;", "</geozet:woonplaats>");
		out = org.apache.commons.lang.StringUtils.replace(out, "&lt;geozet:x&gt;", "<geozet:x>");
		out = org.apache.commons.lang.StringUtils.replace(out, "&lt;/geozet:x&gt;", "</geozet:x>");
		out = org.apache.commons.lang.StringUtils.replace(out, "&lt;geozet:y&gt;", "<geozet:y>");
		out = org.apache.commons.lang.StringUtils.replace(out, "&lt;/geozet:y&gt;", "</geozet:y>");
		out = org.apache.commons.lang.StringUtils.replace(out, "&lt;geozet:pc4&gt;", "<geozet:pc4>");
		out = org.apache.commons.lang.StringUtils.replace(out, "&lt;/geozet:pc4&gt;", "</geozet:pc4>");

		LOGGER.trace("Dit wordt de output");
		LOGGER.trace(out);
		return out;
		
	}

}
