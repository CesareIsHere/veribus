-- The poller reads the active network version (network_meta.version) to know when the trip data it remembers between
-- cycles is out of date. Applied to the project on 2026-10-11 as this same version; running it again is harmless.
grant select on network_meta.version to poller;
