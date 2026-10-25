-- docker exec -it jetlog-pg psql -U jetlog -d jetlog



-- SELECT * FROM entries LIMIT 100;
-- SELECT * FROM rules LIMIT 100;



-- DELETE FROM entries WHERE id = 1;

-- -- if this id is a host, delete its guests first
-- DELETE FROM entries WHERE host_entry_id = 123;
-- DELETE FROM entries WHERE id = 123;

-- DELETE FROM entries WHERE is_guest = true;
-- DELETE FROM entries;

-- SELECT id, flight_number, is_guest, host_entry_id FROM entries ORDER BY id;
-- SELECT COUNT(*) FROM entries;


--