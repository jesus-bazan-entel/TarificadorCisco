--
-- PostgreSQL database dump
--

-- Dumped from database version 15.12 (Debian 15.12-0+deb12u2)
-- Dumped by pg_dump version 15.12 (Debian 15.12-0+deb12u2)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: tarificador_user
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO tarificador_user;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: get_zone_for_number(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_zone_for_number(numero text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    clean_number TEXT;
    zona_result INTEGER;
    prefijo_record RECORD;
BEGIN
    -- Limpiar número (solo dígitos)
    clean_number := regexp_replace(numero, '[^0-9]', '', 'g');
    
    -- Si está vacío, retorna zona por defecto
    IF clean_number = '' OR clean_number IS NULL THEN
        RETURN 1;
    END IF;
    
    -- Buscar prefijo que coincida (ordenado por longitud descendente para priorizar específicos)
    FOR prefijo_record IN 
        SELECT zona_id, prefijo, longitud_minima, longitud_maxima
        FROM prefijos 
        ORDER BY LENGTH(prefijo) DESC, prefijo
    LOOP
        -- Verificar si el número empieza con este prefijo
        IF clean_number LIKE prefijo_record.prefijo || '%' THEN
            -- Verificar longitud
            IF (prefijo_record.longitud_minima IS NULL OR LENGTH(clean_number) >= prefijo_record.longitud_minima) AND
               (prefijo_record.longitud_maxima IS NULL OR LENGTH(clean_number) <= prefijo_record.longitud_maxima) THEN
                RETURN prefijo_record.zona_id;
            END IF;
        END IF;
    END LOOP;
    
    -- Si no encuentra coincidencia, retorna zona por defecto
    RETURN 1;
END;
$$;


ALTER FUNCTION public.get_zone_for_number(numero text) OWNER TO postgres;

--
-- Name: active_calls_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.active_calls_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.active_calls_id_seq OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: active_calls; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.active_calls (
    id integer DEFAULT nextval('public.active_calls_id_seq'::regclass) NOT NULL,
    call_id character varying(50),
    calling_number character varying(20),
    called_number character varying(20),
    start_time timestamp with time zone,
    last_updated timestamp with time zone,
    current_duration integer,
    current_cost numeric(10,2),
    connection_id character varying(100),
    zone character varying(50) DEFAULT 'Desconocida'::character varying
);


ALTER TABLE public.active_calls OWNER TO postgres;

--
-- Name: anexos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.anexos (
    id integer NOT NULL,
    numero character varying(20) NOT NULL,
    usuario character varying(100) NOT NULL,
    area_nivel1 character varying(100) NOT NULL,
    area_nivel2 character varying(100),
    area_nivel3 character varying(100),
    pin character varying(10),
    saldo_actual numeric(10,2) DEFAULT 0,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    activo boolean DEFAULT true,
    CONSTRAINT check_pin_length_flexible CHECK (((pin IS NULL) OR ((pin)::text = ''::text) OR ((char_length((pin)::text) >= 4) AND (char_length((pin)::text) <= 10)))),
    CONSTRAINT check_pin_numeric_flexible CHECK (((pin IS NULL) OR ((pin)::text = ''::text) OR ((pin)::text ~ '^[0-9]+$'::text)))
);


ALTER TABLE public.anexos OWNER TO postgres;

--
-- Name: anexos_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.anexos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.anexos_id_seq OWNER TO postgres;

--
-- Name: anexos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.anexos_id_seq OWNED BY public.anexos.id;


--
-- Name: cdr; Type: TABLE; Schema: public; Owner: tarificador_user
--

CREATE TABLE public.cdr (
    id integer NOT NULL,
    calling_number character varying,
    called_number character varying,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    duration_seconds integer,
    cost numeric(15,6),
    status character varying,
    zona_id integer,
    connect_time timestamp without time zone,
    direction character varying(20) DEFAULT 'unknown'::character varying,
    release_cause integer DEFAULT 0,
    duration_billable integer,
    dialing_time timestamp without time zone,
    network_reached_time timestamp without time zone,
    network_alerting_time timestamp without time zone
);


ALTER TABLE public.cdr OWNER TO tarificador_user;

--
-- Name: cdr_id_seq; Type: SEQUENCE; Schema: public; Owner: tarificador_user
--

CREATE SEQUENCE public.cdr_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.cdr_id_seq OWNER TO tarificador_user;

--
-- Name: cdr_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: tarificador_user
--

ALTER SEQUENCE public.cdr_id_seq OWNED BY public.cdr.id;


--
-- Name: configuracion; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.configuracion (
    id integer NOT NULL,
    clave character varying(50) NOT NULL,
    valor character varying(255) NOT NULL,
    descripcion character varying(255)
);


ALTER TABLE public.configuracion OWNER TO postgres;

--
-- Name: configuracion_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.configuracion_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.configuracion_id_seq OWNER TO postgres;

--
-- Name: configuracion_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.configuracion_id_seq OWNED BY public.configuracion.id;


--
-- Name: cucm_config; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cucm_config (
    id integer NOT NULL,
    server_ip character varying(255) NOT NULL,
    server_port integer DEFAULT 2748,
    username character varying(255) NOT NULL,
    password character varying(255) NOT NULL,
    app_info character varying(255) DEFAULT 'TarificadorApp'::character varying,
    reconnect_delay integer DEFAULT 30,
    check_interval integer DEFAULT 60,
    enabled boolean DEFAULT true,
    last_updated timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_status character varying(255) DEFAULT 'unknown'::character varying,
    last_status_update timestamp without time zone
);


ALTER TABLE public.cucm_config OWNER TO postgres;

--
-- Name: cucm_config_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.cucm_config_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.cucm_config_id_seq OWNER TO postgres;

--
-- Name: cucm_config_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.cucm_config_id_seq OWNED BY public.cucm_config.id;


--
-- Name: fac_audit; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fac_audit (
    id integer NOT NULL,
    authorization_code character varying(255) NOT NULL,
    action character varying(50) NOT NULL,
    admin_user character varying(255) NOT NULL,
    "timestamp" timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    details text,
    success boolean DEFAULT true
);


ALTER TABLE public.fac_audit OWNER TO postgres;

--
-- Name: fac_audit_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.fac_audit_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.fac_audit_id_seq OWNER TO postgres;

--
-- Name: fac_audit_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.fac_audit_id_seq OWNED BY public.fac_audit.id;


--
-- Name: fac_codes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fac_codes (
    id integer NOT NULL,
    authorization_code character varying(255) NOT NULL,
    authorization_code_name character varying(255) NOT NULL,
    authorization_level integer NOT NULL,
    description character varying(255),
    active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    cucm_synced boolean DEFAULT false
);


ALTER TABLE public.fac_codes OWNER TO postgres;

--
-- Name: fac_codes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.fac_codes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.fac_codes_id_seq OWNER TO postgres;

--
-- Name: fac_codes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.fac_codes_id_seq OWNED BY public.fac_codes.id;


--
-- Name: jtapi_logs; Type: TABLE; Schema: public; Owner: tarificador_user
--

CREATE TABLE public.jtapi_logs (
    id integer NOT NULL,
    "timestamp" timestamp without time zone DEFAULT now(),
    nivel character varying,
    mensaje text
);


ALTER TABLE public.jtapi_logs OWNER TO tarificador_user;

--
-- Name: jtapi_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: tarificador_user
--

CREATE SEQUENCE public.jtapi_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.jtapi_logs_id_seq OWNER TO tarificador_user;

--
-- Name: jtapi_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: tarificador_user
--

ALTER SEQUENCE public.jtapi_logs_id_seq OWNED BY public.jtapi_logs.id;


--
-- Name: prefijos; Type: TABLE; Schema: public; Owner: tarificador_user
--

CREATE TABLE public.prefijos (
    id integer NOT NULL,
    zona_id integer,
    prefijo character varying,
    longitud_minima integer,
    longitud_maxima integer
);


ALTER TABLE public.prefijos OWNER TO tarificador_user;

--
-- Name: prefijos_id_seq; Type: SEQUENCE; Schema: public; Owner: tarificador_user
--

CREATE SEQUENCE public.prefijos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.prefijos_id_seq OWNER TO tarificador_user;

--
-- Name: prefijos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: tarificador_user
--

ALTER SEQUENCE public.prefijos_id_seq OWNED BY public.prefijos.id;


--
-- Name: recargas; Type: TABLE; Schema: public; Owner: tarificador_user
--

CREATE TABLE public.recargas (
    id integer NOT NULL,
    calling_number character varying,
    monto numeric(10,2),
    fecha timestamp without time zone DEFAULT now(),
    usuario character varying
);


ALTER TABLE public.recargas OWNER TO tarificador_user;

--
-- Name: recargas_id_seq; Type: SEQUENCE; Schema: public; Owner: tarificador_user
--

CREATE SEQUENCE public.recargas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.recargas_id_seq OWNER TO tarificador_user;

--
-- Name: recargas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: tarificador_user
--

ALTER SEQUENCE public.recargas_id_seq OWNED BY public.recargas.id;


--
-- Name: saldo_anexos; Type: TABLE; Schema: public; Owner: tarificador_user
--

CREATE TABLE public.saldo_anexos (
    id integer NOT NULL,
    calling_number character varying,
    saldo numeric(10,2),
    fecha_ultima_recarga timestamp without time zone DEFAULT now(),
    activo boolean DEFAULT true
);


ALTER TABLE public.saldo_anexos OWNER TO tarificador_user;

--
-- Name: saldo_anexos_id_seq; Type: SEQUENCE; Schema: public; Owner: tarificador_user
--

CREATE SEQUENCE public.saldo_anexos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.saldo_anexos_id_seq OWNER TO tarificador_user;

--
-- Name: saldo_anexos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: tarificador_user
--

ALTER SEQUENCE public.saldo_anexos_id_seq OWNED BY public.saldo_anexos.id;


--
-- Name: saldo_auditoria; Type: TABLE; Schema: public; Owner: tarificador_user
--

CREATE TABLE public.saldo_auditoria (
    id integer NOT NULL,
    calling_number character varying,
    saldo_anterior numeric(10,2),
    saldo_nuevo numeric(10,2),
    tipo_accion character varying,
    fecha timestamp without time zone DEFAULT now(),
    usuario character varying
);


ALTER TABLE public.saldo_auditoria OWNER TO tarificador_user;

--
-- Name: saldo_auditoria_id_seq; Type: SEQUENCE; Schema: public; Owner: tarificador_user
--

CREATE SEQUENCE public.saldo_auditoria_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.saldo_auditoria_id_seq OWNER TO tarificador_user;

--
-- Name: saldo_auditoria_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: tarificador_user
--

ALTER SEQUENCE public.saldo_auditoria_id_seq OWNED BY public.saldo_auditoria.id;


--
-- Name: tarifas; Type: TABLE; Schema: public; Owner: tarificador_user
--

CREATE TABLE public.tarifas (
    id integer NOT NULL,
    zona_id integer,
    tarifa_segundo numeric(10,5),
    fecha_inicio timestamp without time zone,
    activa boolean
);


ALTER TABLE public.tarifas OWNER TO tarificador_user;

--
-- Name: tarifas_id_seq; Type: SEQUENCE; Schema: public; Owner: tarificador_user
--

CREATE SEQUENCE public.tarifas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tarifas_id_seq OWNER TO tarificador_user;

--
-- Name: tarifas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: tarificador_user
--

ALTER SEQUENCE public.tarifas_id_seq OWNED BY public.tarifas.id;


--
-- Name: user_auth_code_audit; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_auth_code_audit (
    id integer NOT NULL,
    extension character varying NOT NULL,
    auth_code character varying NOT NULL,
    action character varying NOT NULL,
    admin_user character varying NOT NULL,
    "timestamp" timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    details character varying
);


ALTER TABLE public.user_auth_code_audit OWNER TO postgres;

--
-- Name: user_auth_code_audit_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_auth_code_audit_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_auth_code_audit_id_seq OWNER TO postgres;

--
-- Name: user_auth_code_audit_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_auth_code_audit_id_seq OWNED BY public.user_auth_code_audit.id;


--
-- Name: user_auth_codes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_auth_codes (
    id integer NOT NULL,
    extension character varying NOT NULL,
    auth_code character varying NOT NULL,
    auth_level integer NOT NULL,
    description character varying,
    active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.user_auth_codes OWNER TO postgres;

--
-- Name: user_auth_codes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_auth_codes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_auth_codes_id_seq OWNER TO postgres;

--
-- Name: user_auth_codes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_auth_codes_id_seq OWNED BY public.user_auth_codes.id;


--
-- Name: usuarios; Type: TABLE; Schema: public; Owner: tarificador_user
--

CREATE TABLE public.usuarios (
    id integer NOT NULL,
    username character varying,
    password character varying,
    nombre character varying,
    apellido character varying,
    email character varying,
    role character varying,
    activo boolean DEFAULT true,
    ultimo_login timestamp without time zone
);


ALTER TABLE public.usuarios OWNER TO tarificador_user;

--
-- Name: usuarios_id_seq; Type: SEQUENCE; Schema: public; Owner: tarificador_user
--

CREATE SEQUENCE public.usuarios_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.usuarios_id_seq OWNER TO tarificador_user;

--
-- Name: usuarios_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: tarificador_user
--

ALTER SEQUENCE public.usuarios_id_seq OWNED BY public.usuarios.id;


--
-- Name: zonas; Type: TABLE; Schema: public; Owner: tarificador_user
--

CREATE TABLE public.zonas (
    id integer NOT NULL,
    nombre character varying,
    descripcion character varying
);


ALTER TABLE public.zonas OWNER TO tarificador_user;

--
-- Name: zonas_id_seq; Type: SEQUENCE; Schema: public; Owner: tarificador_user
--

CREATE SEQUENCE public.zonas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.zonas_id_seq OWNER TO tarificador_user;

--
-- Name: zonas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: tarificador_user
--

ALTER SEQUENCE public.zonas_id_seq OWNED BY public.zonas.id;


--
-- Name: anexos id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.anexos ALTER COLUMN id SET DEFAULT nextval('public.anexos_id_seq'::regclass);


--
-- Name: cdr id; Type: DEFAULT; Schema: public; Owner: tarificador_user
--

ALTER TABLE ONLY public.cdr ALTER COLUMN id SET DEFAULT nextval('public.cdr_id_seq'::regclass);


--
-- Name: configuracion id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.configuracion ALTER COLUMN id SET DEFAULT nextval('public.configuracion_id_seq'::regclass);


--
-- Name: cucm_config id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cucm_config ALTER COLUMN id SET DEFAULT nextval('public.cucm_config_id_seq'::regclass);


--
-- Name: fac_audit id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fac_audit ALTER COLUMN id SET DEFAULT nextval('public.fac_audit_id_seq'::regclass);


--
-- Name: fac_codes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fac_codes ALTER COLUMN id SET DEFAULT nextval('public.fac_codes_id_seq'::regclass);


--
-- Name: jtapi_logs id; Type: DEFAULT; Schema: public; Owner: tarificador_user
--

ALTER TABLE ONLY public.jtapi_logs ALTER COLUMN id SET DEFAULT nextval('public.jtapi_logs_id_seq'::regclass);


--
-- Name: prefijos id; Type: DEFAULT; Schema: public; Owner: tarificador_user
--

ALTER TABLE ONLY public.prefijos ALTER COLUMN id SET DEFAULT nextval('public.prefijos_id_seq'::regclass);


--
-- Name: recargas id; Type: DEFAULT; Schema: public; Owner: tarificador_user
--

ALTER TABLE ONLY public.recargas ALTER COLUMN id SET DEFAULT nextval('public.recargas_id_seq'::regclass);


--
-- Name: saldo_anexos id; Type: DEFAULT; Schema: public; Owner: tarificador_user
--

ALTER TABLE ONLY public.saldo_anexos ALTER COLUMN id SET DEFAULT nextval('public.saldo_anexos_id_seq'::regclass);


--
-- Name: saldo_auditoria id; Type: DEFAULT; Schema: public; Owner: tarificador_user
--

ALTER TABLE ONLY public.saldo_auditoria ALTER COLUMN id SET DEFAULT nextval('public.saldo_auditoria_id_seq'::regclass);


--
-- Name: tarifas id; Type: DEFAULT; Schema: public; Owner: tarificador_user
--

ALTER TABLE ONLY public.tarifas ALTER COLUMN id SET DEFAULT nextval('public.tarifas_id_seq'::regclass);


--
-- Name: user_auth_code_audit id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_auth_code_audit ALTER COLUMN id SET DEFAULT nextval('public.user_auth_code_audit_id_seq'::regclass);


--
-- Name: user_auth_codes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_auth_codes ALTER COLUMN id SET DEFAULT nextval('public.user_auth_codes_id_seq'::regclass);


--
-- Name: usuarios id; Type: DEFAULT; Schema: public; Owner: tarificador_user
--

ALTER TABLE ONLY public.usuarios ALTER COLUMN id SET DEFAULT nextval('public.usuarios_id_seq'::regclass);


--
-- Name: zonas id; Type: DEFAULT; Schema: public; Owner: tarificador_user
--

ALTER TABLE ONLY public.zonas ALTER COLUMN id SET DEFAULT nextval('public.zonas_id_seq'::regclass);


--
-- Name: active_calls active_calls_call_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.active_calls
    ADD CONSTRAINT active_calls_call_id_key UNIQUE (call_id);


--
-- Name: active_calls active_calls_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.active_calls
    ADD CONSTRAINT active_calls_pkey PRIMARY KEY (id);


--
-- Name: anexos anexos_numero_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.anexos
    ADD CONSTRAINT anexos_numero_key UNIQUE (numero);


--
-- Name: anexos anexos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.anexos
    ADD CONSTRAINT anexos_pkey PRIMARY KEY (id);


--
-- Name: cdr cdr_pkey; Type: CONSTRAINT; Schema: public; Owner: tarificador_user
--

ALTER TABLE ONLY public.cdr
    ADD CONSTRAINT cdr_pkey PRIMARY KEY (id);


--
-- Name: configuracion configuracion_clave_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.configuracion
    ADD CONSTRAINT configuracion_clave_key UNIQUE (clave);


--
-- Name: configuracion configuracion_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.configuracion
    ADD CONSTRAINT configuracion_pkey PRIMARY KEY (id);


--
-- Name: cucm_config cucm_config_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cucm_config
    ADD CONSTRAINT cucm_config_pkey PRIMARY KEY (id);


--
-- Name: fac_audit fac_audit_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fac_audit
    ADD CONSTRAINT fac_audit_pkey PRIMARY KEY (id);


--
-- Name: fac_codes fac_codes_authorization_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fac_codes
    ADD CONSTRAINT fac_codes_authorization_code_key UNIQUE (authorization_code);


--
-- Name: fac_codes fac_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fac_codes
    ADD CONSTRAINT fac_codes_pkey PRIMARY KEY (id);


--
-- Name: jtapi_logs jtapi_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: tarificador_user
--

ALTER TABLE ONLY public.jtapi_logs
    ADD CONSTRAINT jtapi_logs_pkey PRIMARY KEY (id);


--
-- Name: prefijos prefijos_pkey; Type: CONSTRAINT; Schema: public; Owner: tarificador_user
--

ALTER TABLE ONLY public.prefijos
    ADD CONSTRAINT prefijos_pkey PRIMARY KEY (id);


--
-- Name: recargas recargas_pkey; Type: CONSTRAINT; Schema: public; Owner: tarificador_user
--

ALTER TABLE ONLY public.recargas
    ADD CONSTRAINT recargas_pkey PRIMARY KEY (id);


--
-- Name: saldo_anexos saldo_anexos_calling_number_key; Type: CONSTRAINT; Schema: public; Owner: tarificador_user
--

ALTER TABLE ONLY public.saldo_anexos
    ADD CONSTRAINT saldo_anexos_calling_number_key UNIQUE (calling_number);


--
-- Name: saldo_anexos saldo_anexos_pkey; Type: CONSTRAINT; Schema: public; Owner: tarificador_user
--

ALTER TABLE ONLY public.saldo_anexos
    ADD CONSTRAINT saldo_anexos_pkey PRIMARY KEY (id);


--
-- Name: saldo_auditoria saldo_auditoria_pkey; Type: CONSTRAINT; Schema: public; Owner: tarificador_user
--

ALTER TABLE ONLY public.saldo_auditoria
    ADD CONSTRAINT saldo_auditoria_pkey PRIMARY KEY (id);


--
-- Name: tarifas tarifas_pkey; Type: CONSTRAINT; Schema: public; Owner: tarificador_user
--

ALTER TABLE ONLY public.tarifas
    ADD CONSTRAINT tarifas_pkey PRIMARY KEY (id);


--
-- Name: user_auth_code_audit user_auth_code_audit_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_auth_code_audit
    ADD CONSTRAINT user_auth_code_audit_pkey PRIMARY KEY (id);


--
-- Name: user_auth_codes user_auth_codes_auth_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_auth_codes
    ADD CONSTRAINT user_auth_codes_auth_code_key UNIQUE (auth_code);


--
-- Name: user_auth_codes user_auth_codes_extension_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_auth_codes
    ADD CONSTRAINT user_auth_codes_extension_key UNIQUE (extension);


--
-- Name: user_auth_codes user_auth_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_auth_codes
    ADD CONSTRAINT user_auth_codes_pkey PRIMARY KEY (id);


--
-- Name: usuarios usuarios_pkey; Type: CONSTRAINT; Schema: public; Owner: tarificador_user
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_pkey PRIMARY KEY (id);


--
-- Name: usuarios usuarios_username_key; Type: CONSTRAINT; Schema: public; Owner: tarificador_user
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_username_key UNIQUE (username);


--
-- Name: zonas zonas_nombre_key; Type: CONSTRAINT; Schema: public; Owner: tarificador_user
--

ALTER TABLE ONLY public.zonas
    ADD CONSTRAINT zonas_nombre_key UNIQUE (nombre);


--
-- Name: zonas zonas_pkey; Type: CONSTRAINT; Schema: public; Owner: tarificador_user
--

ALTER TABLE ONLY public.zonas
    ADD CONSTRAINT zonas_pkey PRIMARY KEY (id);


--
-- Name: idx_cdr_connect_time; Type: INDEX; Schema: public; Owner: tarificador_user
--

CREATE INDEX idx_cdr_connect_time ON public.cdr USING btree (connect_time);


--
-- Name: idx_cdr_direction; Type: INDEX; Schema: public; Owner: tarificador_user
--

CREATE INDEX idx_cdr_direction ON public.cdr USING btree (direction);


--
-- Name: idx_cdr_release_cause; Type: INDEX; Schema: public; Owner: tarificador_user
--

CREATE INDEX idx_cdr_release_cause ON public.cdr USING btree (release_cause);


--
-- Name: idx_cdr_status; Type: INDEX; Schema: public; Owner: tarificador_user
--

CREATE INDEX idx_cdr_status ON public.cdr USING btree (status);


--
-- Name: idx_fac_audit_code; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fac_audit_code ON public.fac_audit USING btree (authorization_code);


--
-- Name: idx_fac_audit_timestamp; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fac_audit_timestamp ON public.fac_audit USING btree ("timestamp");


--
-- Name: idx_fac_codes_code; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fac_codes_code ON public.fac_codes USING btree (authorization_code);


--
-- Name: idx_user_auth_code_audit_extension; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_auth_code_audit_extension ON public.user_auth_code_audit USING btree (extension);


--
-- Name: idx_user_auth_codes_extension; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_auth_codes_extension ON public.user_auth_codes USING btree (extension);


--
-- Name: ix_prefijos_id; Type: INDEX; Schema: public; Owner: tarificador_user
--

CREATE INDEX ix_prefijos_id ON public.prefijos USING btree (id);


--
-- Name: ix_tarifas_id; Type: INDEX; Schema: public; Owner: tarificador_user
--

CREATE INDEX ix_tarifas_id ON public.tarifas USING btree (id);


--
-- Name: ix_zonas_id; Type: INDEX; Schema: public; Owner: tarificador_user
--

CREATE INDEX ix_zonas_id ON public.zonas USING btree (id);


--
-- Name: cdr fk_cdr_zona; Type: FK CONSTRAINT; Schema: public; Owner: tarificador_user
--

ALTER TABLE ONLY public.cdr
    ADD CONSTRAINT fk_cdr_zona FOREIGN KEY (zona_id) REFERENCES public.zonas(id);


--
-- Name: prefijos prefijos_zona_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tarificador_user
--

ALTER TABLE ONLY public.prefijos
    ADD CONSTRAINT prefijos_zona_id_fkey FOREIGN KEY (zona_id) REFERENCES public.zonas(id);


--
-- Name: tarifas tarifas_zona_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tarificador_user
--

ALTER TABLE ONLY public.tarifas
    ADD CONSTRAINT tarifas_zona_id_fkey FOREIGN KEY (zona_id) REFERENCES public.zonas(id);


--
-- Name: SEQUENCE active_calls_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.active_calls_id_seq TO tarificador_user;


--
-- Name: TABLE active_calls; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.active_calls TO tarificador_user;


--
-- Name: TABLE anexos; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.anexos TO tarificador_user;


--
-- Name: SEQUENCE anexos_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.anexos_id_seq TO tarificador_user;


--
-- Name: TABLE configuracion; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.configuracion TO tarificador_user;


--
-- Name: SEQUENCE configuracion_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.configuracion_id_seq TO tarificador_user;


--
-- Name: TABLE cucm_config; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.cucm_config TO tarificador_user;


--
-- Name: SEQUENCE cucm_config_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.cucm_config_id_seq TO tarificador_user;


--
-- Name: TABLE fac_audit; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.fac_audit TO tarificador_user;


--
-- Name: SEQUENCE fac_audit_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.fac_audit_id_seq TO tarificador_user;


--
-- Name: TABLE fac_codes; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.fac_codes TO tarificador_user;


--
-- Name: SEQUENCE fac_codes_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.fac_codes_id_seq TO tarificador_user;


--
-- Name: TABLE user_auth_code_audit; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.user_auth_code_audit TO tarificador_user;


--
-- Name: SEQUENCE user_auth_code_audit_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.user_auth_code_audit_id_seq TO tarificador_user;


--
-- Name: TABLE user_auth_codes; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.user_auth_codes TO tarificador_user;


--
-- Name: SEQUENCE user_auth_codes_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.user_auth_codes_id_seq TO tarificador_user;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES  TO tarificador_user;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES  TO tarificador_user;


--
-- PostgreSQL database dump complete
--

