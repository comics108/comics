-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.tokens (
  id integer NOT NULL DEFAULT nextval('tokens_id_seq'::regclass),
  key character varying NOT NULL,
  CONSTRAINT tokens_pkey PRIMARY KEY (id)
);
CREATE TABLE public.tokens_localized (
  id integer NOT NULL,
  culture USER-DEFINED NOT NULL,
  text text,
  CONSTRAINT tokens_localized_pkey PRIMARY KEY (id, culture)
);
CREATE TABLE public.devices (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  platform USER-DEFINED NOT NULL,
  os_version character varying NOT NULL,
  device_id character varying NOT NULL,
  model character varying NOT NULL,
  app_version character varying NOT NULL,
  timezone_offset integer NOT NULL,
  culture USER-DEFINED NOT NULL,
  push_token text,
  last_modified timestamp without time zone NOT NULL DEFAULT now(),
  CONSTRAINT devices_pkey PRIMARY KEY (id)
);
CREATE TABLE public.seasons (
  id integer NOT NULL DEFAULT nextval('seasons_id_seq'::regclass),
  name_token_id integer NOT NULL,
  image character varying,
  product character varying,
  order integer NOT NULL,
  CONSTRAINT seasons_pkey PRIMARY KEY (id),
  CONSTRAINT seasons_name_token_id_fkey FOREIGN KEY (name_token_id) REFERENCES public.tokens(id)
);
CREATE TABLE public.episodes (
  id integer NOT NULL DEFAULT nextval('episodes_id_seq'::regclass),
  season_id integer NOT NULL,
  name_token_id integer NOT NULL,
  image character varying,
  file character varying,
  version integer NOT NULL DEFAULT 1,
  product character varying,
  date date NOT NULL DEFAULT CURRENT_DATE,
  order integer NOT NULL,
  CONSTRAINT episodes_pkey PRIMARY KEY (id),
  CONSTRAINT episodes_season_id_fkey FOREIGN KEY (season_id) REFERENCES public.seasons(id),
  CONSTRAINT episodes_name_token_id_fkey FOREIGN KEY (name_token_id) REFERENCES public.tokens(id)
);
CREATE TABLE public.music (
  id integer NOT NULL DEFAULT nextval('music_id_seq'::regclass),
  name_token_id integer NOT NULL,
  author_token_id integer NOT NULL,
  file character varying,
  order integer NOT NULL,
  CONSTRAINT music_pkey PRIMARY KEY (id),
  CONSTRAINT music_name_token_id_fkey FOREIGN KEY (name_token_id) REFERENCES public.tokens(id),
  CONSTRAINT music_author_token_id_fkey FOREIGN KEY (author_token_id) REFERENCES public.tokens(id)
);
CREATE TABLE public.puzzles (
  id integer NOT NULL DEFAULT nextval('puzzles_id_seq'::regclass),
  name_token_id integer NOT NULL,
  width integer NOT NULL,
  height integer NOT NULL,
  order integer NOT NULL,
  CONSTRAINT puzzles_pkey PRIMARY KEY (id),
  CONSTRAINT puzzles_name_token_id_fkey FOREIGN KEY (name_token_id) REFERENCES public.tokens(id)
);
CREATE TABLE public.pieces (
  id integer NOT NULL DEFAULT nextval('pieces_id_seq'::regclass),
  puzzle_id integer NOT NULL,
  x integer NOT NULL,
  y integer NOT NULL,
  width integer NOT NULL,
  height integer NOT NULL,
  file character varying,
  version integer NOT NULL DEFAULT 1,
  date date NOT NULL DEFAULT CURRENT_DATE,
  order integer NOT NULL,
  CONSTRAINT pieces_pkey PRIMARY KEY (id),
  CONSTRAINT pieces_puzzle_id_fkey FOREIGN KEY (puzzle_id) REFERENCES public.puzzles(id)
);
CREATE TABLE public.quotes (
  id integer NOT NULL DEFAULT nextval('quotes_id_seq'::regclass),
  name_token_id integer NOT NULL,
  image_token_id integer NOT NULL,
  publish_date timestamp without time zone,
  CONSTRAINT quotes_pkey PRIMARY KEY (id),
  CONSTRAINT quotes_name_token_id_fkey FOREIGN KEY (name_token_id) REFERENCES public.tokens(id),
  CONSTRAINT quotes_image_token_id_fkey FOREIGN KEY (image_token_id) REFERENCES public.tokens(id)
);
