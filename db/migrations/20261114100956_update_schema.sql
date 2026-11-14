-- migrate:up

CREATE TYPE public.membership_plan AS ENUM (
    'Single Visit',
    'Monthly Basic',
    'Quarterly Standard',
    'Annual Unlimited',
    'Morning / Off-Peak',
    'Weekend Pass',
    '10-Visit Pack',
    'Group Classes Plus',
    'VIP All-Inclusive',
    'Student Plan'
);

ALTER TABLE public.membership_types
    ALTER COLUMN name TYPE public.membership_plan
        USING name::text::public.membership_plan;

ALTER TABLE public.membership_types
    ADD COLUMN description text GENERATED ALWAYS AS (
        CASE name
            WHEN 'Single Visit' THEN
                'Разовый — однократный доступ в тренажерный зал в течение одного календарного дня.'
            WHEN 'Monthly Basic' THEN
                'Базовый месячный — безлимитное посещение тренажёрного зала в любое время работы клуба на 30 дней.'
            WHEN 'Quarterly Standard' THEN
                'Квартальный — безлимитный доступ в тренажерный зал на 90 дней без дополнительных услуг.'
            WHEN 'Annual Unlimited' THEN
                'Годовой безлимит — полный доступ в зал на 365 дней с возможностью заморозки абонемента.'
            WHEN 'Morning / Off-Peak' THEN
                'Дневной — безлимитный абонемент на 30 дней с доступом строго в утренние и дневные часы (например, до 16:00).'
            WHEN 'Weekend Pass' THEN
                'Выходного дня — доступ в тренажерный зал только по субботам и воскресеньям в течение 30 дней.'
            WHEN '10-Visit Pack' THEN
                'Пакет на 10 тренировок — абонемент с фиксированным количеством входов, действующий в течение 90 дней.'
            WHEN 'Group Classes Plus' THEN
                'Зал + Групповые — месячный безлимит в тренажерный зал с включенным посещением групповых тренировок.'
            WHEN 'VIP All-Inclusive' THEN
                'Все включено — годовой доступ во все зоны клуба.'
            WHEN 'Student Plan' THEN
                'Студенческий — льготный месячный безлимит в тренажерный зал для студентов очной формы обучения.'
        END
    ) STORED NOT NULL;

ALTER TABLE public.clients
    ALTER COLUMN phone TYPE char(12),
    ALTER COLUMN phone SET NOT NULL,
    ADD CONSTRAINT clients_phone_key UNIQUE (phone),
    ALTER COLUMN birth_date SET NOT NULL,
    ADD COLUMN created_at timestamptz NOT NULL DEFAULT now();

ALTER TABLE public.trainers
    ALTER COLUMN phone TYPE char(12),
    ALTER COLUMN phone SET NOT NULL,
    ADD CONSTRAINT trainers_phone_key UNIQUE (phone),
    ADD COLUMN created_at timestamptz NOT NULL DEFAULT now();

ALTER TABLE public.memberships
    ADD COLUMN created_at timestamptz NOT NULL DEFAULT now(),
    ADD COLUMN client_id integer NOT NULL,
    ADD CONSTRAINT memberships_client_id_fkey
        FOREIGN KEY (client_id) REFERENCES public.clients (client_id);

ALTER TABLE public.clients
    DROP COLUMN membership_id;

ALTER TABLE public.balance_history
    ALTER COLUMN operation_date TYPE timestamptz,
    ALTER COLUMN operation_date SET DEFAULT now(),
    ADD COLUMN created_at timestamptz NOT NULL DEFAULT now();

ALTER TABLE public.payments
    ALTER COLUMN payment_date TYPE timestamptz,
    ALTER COLUMN payment_date SET DEFAULT now(),
    ADD COLUMN created_at timestamptz NOT NULL DEFAULT now();

ALTER TABLE public.visits
    ALTER COLUMN visit_date TYPE timestamptz,
    ALTER COLUMN visit_date SET DEFAULT now(),
    ADD COLUMN created_at timestamptz NOT NULL DEFAULT now();

ALTER TABLE public.schedule
    ADD COLUMN created_at timestamptz NOT NULL DEFAULT now(),
    ADD COLUMN updated_at timestamptz NOT NULL DEFAULT now();

ALTER TABLE public.trainings
    ADD COLUMN created_at timestamptz NOT NULL DEFAULT now();

-- migrate:down

-- Roll back with an empty clients table to avoid discarding membership history.
ALTER TABLE public.clients
    ADD COLUMN membership_id integer NOT NULL,
    ADD CONSTRAINT clients_membership_id_fkey
        FOREIGN KEY (membership_id) REFERENCES public.memberships (membership_id);

ALTER TABLE public.memberships
    DROP COLUMN client_id;

ALTER TABLE public.trainings
    DROP COLUMN created_at;

ALTER TABLE public.schedule
    DROP COLUMN updated_at,
    DROP COLUMN created_at;

ALTER TABLE public.visits
    DROP COLUMN created_at,
    ALTER COLUMN visit_date DROP DEFAULT,
    ALTER COLUMN visit_date TYPE timestamp;

ALTER TABLE public.payments
    DROP COLUMN created_at,
    ALTER COLUMN payment_date DROP DEFAULT,
    ALTER COLUMN payment_date TYPE timestamp;

ALTER TABLE public.balance_history
    DROP COLUMN created_at,
    ALTER COLUMN operation_date DROP DEFAULT,
    ALTER COLUMN operation_date TYPE timestamp;

ALTER TABLE public.memberships
    DROP COLUMN created_at;

ALTER TABLE public.trainers
    DROP COLUMN created_at,
    DROP CONSTRAINT trainers_phone_key,
    ALTER COLUMN phone TYPE varchar(20) USING phone::text;

ALTER TABLE public.clients
    DROP COLUMN created_at,
    ALTER COLUMN birth_date DROP NOT NULL,
    DROP CONSTRAINT clients_phone_key,
    ALTER COLUMN phone TYPE varchar(20) USING phone::text;

ALTER TABLE public.membership_types
    DROP COLUMN description;

ALTER TABLE public.membership_types
    ALTER COLUMN name TYPE varchar(100) USING name::text;

DROP TYPE public.membership_plan;
