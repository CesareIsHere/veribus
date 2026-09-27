-- Network data for the app (RF-11, RNF-10), one compact JSON per version:
--   stops:  [stop_id, name, lat, lon, [route_id...]]
--   routes: [route_id, name, kind, night, [[direction_id, headsign]...]]
select jsonb_build_object(
  'version', :'md5',
  'stops', (
    select jsonb_agg(jsonb_build_array(s.stop_id, s.name, round(s.lat::numeric, 6), round(s.lon::numeric, 6), r.routes)
                     order by s.stop_id)
    from network_import.stop s
    join (select st.stop_id, jsonb_agg(distinct t.route_id) as routes
          from network_import.stop_time st join network_import.trip t using (trip_id) group by st.stop_id) r using (stop_id)
  ),
  'routes', (
    select jsonb_agg(jsonb_build_array(r.route_id, r.name, r.kind, r.night,
                     coalesce((select jsonb_agg(jsonb_build_array(p.direction_id, p.headsign) order by p.direction_id)
                               from network_import.route_path p where p.route_id = r.route_id), '[]'))
                     order by r.route_id)
    from network_import.route r
    where exists (select from network_import.trip t where t.route_id = r.route_id)
  )
)::text;
