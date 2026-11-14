-- Run from the project root, after applying the schema migration.
\set ON_ERROR_STOP on

BEGIN;
SET LOCAL DateStyle TO 'ISO, YMD';
LOCK TABLE public.membership_types, public.memberships, public.clients, public.balance_history, public.payments, public.trainers, public.gym_rooms, public.schedule, public.trainings, public.client_trainings, public.visits IN SHARE ROW EXCLUSIVE MODE;

DO $check$
BEGIN
    IF EXISTS (SELECT 1 FROM public.membership_types)
        OR EXISTS (SELECT 1 FROM public.memberships)
        OR EXISTS (SELECT 1 FROM public.clients)
        OR EXISTS (SELECT 1 FROM public.balance_history)
        OR EXISTS (SELECT 1 FROM public.payments)
        OR EXISTS (SELECT 1 FROM public.trainers)
        OR EXISTS (SELECT 1 FROM public.gym_rooms)
        OR EXISTS (SELECT 1 FROM public.schedule)
        OR EXISTS (SELECT 1 FROM public.trainings)
        OR EXISTS (SELECT 1 FROM public.client_trainings)
        OR EXISTS (SELECT 1 FROM public.visits)
    THEN
        RAISE EXCEPTION 'Seed import requires all 11 target tables to be empty.';
    END IF;
END
$check$;

\copy public.membership_types (type_id, name, duration_days, price) FROM 'seed/membership_types.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy public.memberships (membership_id, type_id, start_date, end_date, price) FROM 'seed/memberships.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy public.clients (client_id, membership_id, full_name, phone, email, birth_date, current_balance) FROM 'seed/clients.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy public.balance_history (history_id, client_id, change_amount, balance_after, operation_type, operation_date) FROM 'seed/balance_history.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy public.payments (payment_id, history_id, amount, payment_date, method) FROM 'seed/payments.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy public.trainers (trainer_id, full_name, specialization, phone) FROM 'seed/trainers.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy public.gym_rooms (room_id, name, capacity) FROM 'seed/gym_rooms.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy public.schedule (schedule_id, name, day_of_week, start_time, end_time, trainer_id, room_id) FROM 'seed/schedule.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy public.trainings (training_id, schedule_id, training_date) FROM 'seed/trainings.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy public.client_trainings (client_id, training_id, status) FROM 'seed/client_trainings.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy public.visits (visit_id, client_id, room_id, visit_date) FROM 'seed/visits.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

-- Explicit IDs loaded by COPY do not advance their sequences.
DO $sequences$
DECLARE
    target record;
    sequence_name text;
    next_id bigint;
BEGIN
    FOR target IN SELECT * FROM (VALUES
        ('membership_types', 'type_id'),
        ('memberships', 'membership_id'),
        ('clients', 'client_id'),
        ('balance_history', 'history_id'),
        ('payments', 'payment_id'),
        ('trainers', 'trainer_id'),
        ('gym_rooms', 'room_id'),
        ('schedule', 'schedule_id'),
        ('trainings', 'training_id'),
        ('visits', 'visit_id')
    ) AS keys(table_name, column_name)
    LOOP
        sequence_name := pg_get_serial_sequence(format('public.%I', target.table_name), target.column_name);
        IF sequence_name IS NULL THEN
            RAISE EXCEPTION 'Missing ID sequence for %.%', target.table_name, target.column_name;
        END IF;
        EXECUTE format('SELECT max(%I)::bigint + 1 FROM public.%I', target.column_name, target.table_name)
            INTO next_id;
        EXECUTE format('ALTER SEQUENCE %s RESTART WITH %s', sequence_name, next_id);
    END LOOP;
END
$sequences$;
COMMIT;

SELECT 'membership_types' AS table_name, count(*) AS rows FROM public.membership_types
UNION ALL
SELECT 'memberships', count(*) FROM public.memberships
UNION ALL
SELECT 'clients', count(*) FROM public.clients
UNION ALL
SELECT 'balance_history', count(*) FROM public.balance_history
UNION ALL
SELECT 'payments', count(*) FROM public.payments
UNION ALL
SELECT 'trainers', count(*) FROM public.trainers
UNION ALL
SELECT 'gym_rooms', count(*) FROM public.gym_rooms
UNION ALL
SELECT 'schedule', count(*) FROM public.schedule
UNION ALL
SELECT 'trainings', count(*) FROM public.trainings
UNION ALL
SELECT 'client_trainings', count(*) FROM public.client_trainings
UNION ALL
SELECT 'visits', count(*) FROM public.visits
ORDER BY table_name;
