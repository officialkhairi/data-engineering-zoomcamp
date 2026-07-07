SELECT * FROM public.green_taxi_trips LIMIT 10;

-- Question 3. Counting short trips
-- For the trips in November 2025 (lpep_pickup_datetime between '2025-11-01' and '2025-12-01', exclusive of the upper bound), how many trips had a trip_distance of less than or equal to 1 mile?

SELECT COUNT(1) 
	FROM public.green_taxi_trips
	WHERE 
		lpep_pickup_datetime >= '2025-11-01' 
	AND  
		lpep_dropoff_datetime <= '2025-12-01'
	AND 
		trip_distance <= 1;

-- Question 4. Longest trip for each day
-- Which was the pick up day with the longest trip distance? Only consider trips with trip_distance less than 100 miles (to exclude data errors).
-- Use the pick up time for your calculations.
-- 2025-11-14 

SELECT
    DATE(lpep_pickup_datetime) AS pickup_day,
    MAX(trip_distance) AS longest_trip
FROM public.green_taxi_trips
WHERE trip_distance < 100
GROUP BY pickup_day
ORDER BY longest_trip DESC
LIMIT 1;


-- Question 5. Biggest pickup zone
-- Which was the pickup zone with the largest total_amount (sum of all trips) on November 18th, 2025?
-- East Harlem North

SELECT * FROM public.taxi_zone_lookup;

SELECT
    zons."Zone",
    SUM(trips.total_amount) AS total
FROM public.green_taxi_trips AS trips
JOIN public.taxi_zone_lookup AS zons
    ON trips."PULocationID" = zons."LocationID"
WHERE
    trips.lpep_pickup_datetime >= '2025-11-18'
    AND trips.lpep_pickup_datetime < '2025-11-19'
GROUP BY zons."Zone"
ORDER BY total DESC
LIMIT 1;

-- Question 6. Largest tip
-- For the passengers picked up in the zone named "East Harlem North" in November 2025, which was the drop off zone that had the largest tip?
-- Note: it's tip , not trip. We need the name of the zone, not the ID.
-- Yorkville West

SELECT
    dropoff_zone."Zone" AS dropoff_zone,
    MAX(trips.tip_amount) AS largest_tip
FROM public.green_taxi_trips AS trips
JOIN public.taxi_zone_lookup AS pickup_zone
    ON trips."PULocationID" = pickup_zone."LocationID"
JOIN public.taxi_zone_lookup AS dropoff_zone
    ON trips."DOLocationID" = dropoff_zone."LocationID"
WHERE
    pickup_zone."Zone" = 'East Harlem North'
    AND trips.lpep_pickup_datetime >= '2025-11-01'
    AND trips.lpep_pickup_datetime < '2025-12-01'
GROUP BY dropoff_zone."Zone"
ORDER BY largest_tip DESC
LIMIT 1;


















