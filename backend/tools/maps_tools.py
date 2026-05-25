"""
Maps Tools — Google Maps / Places API integration for real provider discovery.
"""
import googlemaps
from config import GOOGLE_MAPS_API_KEY


def search_google_maps(service_type: str, location: str, radius_meters: int = 5000) -> dict:
    """
    Search Google Maps Places API for real service providers near a location.
    
    Args:
        service_type: Type of service to search for
        location: Area/sector name (e.g., "G-13")
        radius_meters: Search radius in meters (default: 5000)
    
    Returns:
        List of places found from Google Maps
    """
    if not GOOGLE_MAPS_API_KEY:
        return {"status": "error", "message": "Google Maps API key not configured."}

    try:
        gmaps = googlemaps.Client(key=GOOGLE_MAPS_API_KEY)

        # Resolve the requested area through Google Maps.
        geocoded = geocode_location(location)
        if geocoded.get("error"):
            return {"status": "error", "message": geocoded["error"]}
        coords = (geocoded["lat"], geocoded["lng"])
        
        # Map service types to search queries
        search_queries = {
            "ac_technician": "AC repair technician service",
            "plumber": "plumber plumbing service",
            "electrician": "electrician electrical service",
            "tutor": "tutor tuition academy",
            "beautician": "beauty salon parlour",
            "carpenter": "carpenter furniture repair",
            "painter": "painter painting service",
            "home_cleaner": "home cleaning service",
            "mechanic": "car mechanic auto repair",
        }
        
        query = search_queries.get(service_type, service_type)
        
        # Search nearby places
        results = gmaps.places_nearby(
            location=coords,
            radius=radius_meters,
            keyword=query
        )
        
        places = []
        for place in results.get("results", [])[:5]:
            places.append({
                "name": place.get("name", ""),
                "address": place.get("vicinity", ""),
                "rating": place.get("rating", 0),
                "total_reviews": place.get("user_ratings_total", 0),
                "lat": place["geometry"]["location"]["lat"],
                "lng": place["geometry"]["location"]["lng"],
                "place_id": place.get("place_id", ""),
                "is_open": place.get("opening_hours", {}).get("open_now", None),
                "source": "google_maps"
            })
        
        return {"status": "success", "places": places, "count": len(places)}
    
    except Exception as e:
        return {"status": "error", "message": str(e)}


def geocode_location(location_name: str) -> dict:
    """
    Convert a location name to coordinates using Google Geocoding API.
    
    Args:
        location_name: Name of the location (e.g., "G-13 Islamabad")
    
    Returns:
        Dictionary with lat, lng, and formatted_address
    """
    if not GOOGLE_MAPS_API_KEY:
        return {"error": "Google Maps API key not configured."}
    
    try:
        gmaps = googlemaps.Client(key=GOOGLE_MAPS_API_KEY)
        result = gmaps.geocode(f"{location_name}, Islamabad, Pakistan")
        if result:
            loc = result[0]["geometry"]["location"]
            return {
                "lat": loc["lat"],
                "lng": loc["lng"],
                "formatted_address": result[0].get("formatted_address", location_name)
            }
    except Exception as e:
        return {"error": str(e)}
    
    return {"error": f"Unable to geocode location: {location_name}"}
