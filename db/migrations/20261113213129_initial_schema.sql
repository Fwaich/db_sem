-- migrate:up

CREATE TYPE public.weekday AS ENUM (
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday'
);

CREATE TYPE public.training_status AS ENUM (
    'registered',
    'attended',
    'cancelled',
    'no_show'
);

CREATE TYPE public.balance_operation AS ENUM (
    'top_up',
    'debit',
    'refund',
    'adjustment'
);

CREATE TYPE public.payment_method AS ENUM (
    'cash',
    'card',
    'bank_transfer'
);

CREATE TABLE public.membership_types (
    type_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name varchar(100) NOT NULL,
    duration_days integer NOT NULL,
    price numeric(10,2) NOT NULL
);

CREATE TABLE public.memberships (
    membership_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    type_id integer NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    price numeric(10,2) NOT NULL,
    FOREIGN KEY (type_id) REFERENCES public.membership_types (type_id)
);

CREATE TABLE public.clients (
    client_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    membership_id integer NOT NULL,
    full_name varchar(150) NOT NULL,
    phone varchar(20) NOT NULL,
    email varchar(100),
    birth_date date,
    current_balance numeric(10,2) NOT NULL,
    FOREIGN KEY (membership_id) REFERENCES public.memberships (membership_id)
);

CREATE TABLE public.balance_history (
    history_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id integer NOT NULL,
    change_amount numeric(10,2) NOT NULL,
    balance_after numeric(10,2) NOT NULL,
    operation_type public.balance_operation NOT NULL,
    operation_date timestamp NOT NULL,
    FOREIGN KEY (client_id) REFERENCES public.clients (client_id)
);

CREATE TABLE public.payments (
    payment_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    history_id integer NOT NULL UNIQUE,
    amount numeric(10,2) NOT NULL,
    payment_date timestamp NOT NULL,
    method public.payment_method NOT NULL,
    FOREIGN KEY (history_id) REFERENCES public.balance_history (history_id)
);

CREATE TABLE public.trainers (
    trainer_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name varchar(150) NOT NULL,
    specialization varchar(100),
    phone varchar(20) NOT NULL
);

CREATE TABLE public.gym_rooms (
    room_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name varchar(50) NOT NULL,
    capacity integer NOT NULL
);

CREATE TABLE public.schedule (
    schedule_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name varchar(100) NOT NULL,
    day_of_week public.weekday NOT NULL,
    start_time time NOT NULL,
    end_time time NOT NULL,
    trainer_id integer NOT NULL,
    room_id integer NOT NULL,
    FOREIGN KEY (trainer_id) REFERENCES public.trainers (trainer_id),
    FOREIGN KEY (room_id) REFERENCES public.gym_rooms (room_id)
);

CREATE TABLE public.trainings (
    training_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    schedule_id integer NOT NULL,
    training_date date NOT NULL,
    FOREIGN KEY (schedule_id) REFERENCES public.schedule (schedule_id)
);

CREATE TABLE public.client_trainings (
    client_id integer NOT NULL,
    training_id integer NOT NULL,
    status public.training_status,
    PRIMARY KEY (client_id, training_id),
    FOREIGN KEY (client_id) REFERENCES public.clients (client_id),
    FOREIGN KEY (training_id) REFERENCES public.trainings (training_id)
);

CREATE TABLE public.visits (
    visit_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id integer NOT NULL,
    room_id integer NOT NULL,
    visit_date timestamp NOT NULL,
    FOREIGN KEY (client_id) REFERENCES public.clients (client_id),
    FOREIGN KEY (room_id) REFERENCES public.gym_rooms (room_id)
);


-- migrate:down

DROP TABLE public.visits;
DROP TABLE public.client_trainings;
DROP TABLE public.trainings;
DROP TABLE public.schedule;
DROP TABLE public.gym_rooms;
DROP TABLE public.trainers;
DROP TABLE public.payments;
DROP TABLE public.balance_history;
DROP TABLE public.clients;
DROP TABLE public.memberships;
DROP TABLE public.membership_types;

DROP TYPE public.payment_method;
DROP TYPE public.balance_operation;
DROP TYPE public.training_status;
DROP TYPE public.weekday;


