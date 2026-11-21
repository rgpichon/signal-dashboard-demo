--
-- PostgreSQL database dump
--


-- Dumped from database version 15.17 (Homebrew)
-- Dumped by pg_dump version 15.17 (Homebrew)

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
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: anomalies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.anomalies (
    id integer NOT NULL,
    detected_at timestamp with time zone NOT NULL,
    anomaly_type character varying(32) NOT NULL,
    topic character varying(64),
    series_id character varying(64),
    severity double precision,
    description text,
    resolved boolean DEFAULT false
);


--
-- Name: anomalies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.anomalies_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: anomalies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.anomalies_id_seq OWNED BY public.anomalies.id;


--
-- Name: articles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.articles (
    id integer NOT NULL,
    source_id character varying(64) NOT NULL,
    url text NOT NULL,
    title text,
    body_text text,
    published_at timestamp with time zone,
    ingested_at timestamp with time zone DEFAULT now(),
    entities jsonb,
    topics jsonb,
    sentiment double precision,
    sentiment_conf double precision,
    processed boolean DEFAULT false
);


--
-- Name: articles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.articles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: articles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.articles_id_seq OWNED BY public.articles.id;


--
-- Name: beta_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.beta_metadata (
    id integer NOT NULL,
    base_series_id character varying(50) NOT NULL,
    target_series_id character varying(50) NOT NULL,
    optimal_decay double precision,
    break_date date,
    break_detected boolean DEFAULT false,
    last_computed timestamp with time zone DEFAULT now()
);


--
-- Name: beta_metadata_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.beta_metadata_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: beta_metadata_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.beta_metadata_id_seq OWNED BY public.beta_metadata.id;


--
-- Name: correlations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.correlations (
    id integer NOT NULL,
    topic character varying(64) NOT NULL,
    series_id character varying(64) NOT NULL,
    lag_days integer NOT NULL,
    correlation double precision,
    p_value double precision,
    window_days integer,
    computed_at date NOT NULL,
    quality character varying(16) DEFAULT 'ok'::character varying
);


--
-- Name: correlations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.correlations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: correlations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.correlations_id_seq OWNED BY public.correlations.id;


--
-- Name: daily_signals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.daily_signals (
    id integer NOT NULL,
    date date NOT NULL,
    topic character varying(64) NOT NULL,
    article_count integer,
    velocity_7d double precision,
    sentiment_avg double precision,
    sentiment_std double precision,
    source_count integer,
    divergence_flag boolean,
    anomaly_flag boolean,
    data_quality text DEFAULT 'ok'::text,
    CONSTRAINT daily_signals_data_quality_check CHECK ((data_quality = ANY (ARRAY['ok'::text, 'velocity_cold_start'::text, 'insufficient_data'::text])))
);


--
-- Name: daily_signals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.daily_signals_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: daily_signals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.daily_signals_id_seq OWNED BY public.daily_signals.id;


--
-- Name: factor_decomposition_cache; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.factor_decomposition_cache (
    instrument_id text NOT NULL,
    decomposition jsonb NOT NULL,
    computed_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone NOT NULL
);


--
-- Name: instruments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.instruments (
    id character varying(32) NOT NULL,
    name text,
    asset_class character varying(32),
    sub_type character varying(32),
    geography text[],
    sectors text[],
    themes text[],
    risk_profile character varying(16),
    liquidity character varying(16),
    yfinance_ticker character varying(16),
    fred_series_id character varying(32),
    correlates_with text[],
    thesis_role text[],
    tradeable_via text[],
    sector text,
    country text DEFAULT 'US'::text,
    market_cap text,
    currency text DEFAULT 'USD'::text,
    index_member text[] DEFAULT '{}'::text[],
    is_active boolean DEFAULT true,
    last_synced timestamp with time zone
);


--
-- Name: market_data; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.market_data (
    id integer NOT NULL,
    date date NOT NULL,
    series_id character varying(64) NOT NULL,
    value double precision,
    daily_chg double precision,
    pct_chg double precision,
    source character varying(32) NOT NULL
);


--
-- Name: market_data_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.market_data_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: market_data_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.market_data_id_seq OWNED BY public.market_data.id;


--
-- Name: pipeline_errors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pipeline_errors (
    id integer NOT NULL,
    source_id character varying(64) NOT NULL,
    error_type character varying(64),
    error_msg text,
    "timestamp" timestamp with time zone DEFAULT now()
);


--
-- Name: pipeline_errors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pipeline_errors_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pipeline_errors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pipeline_errors_id_seq OWNED BY public.pipeline_errors.id;


--
-- Name: positioning_signals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.positioning_signals (
    id integer NOT NULL,
    date date NOT NULL,
    series_id character varying(64) NOT NULL,
    net_spec double precision,
    percentile_52w double precision,
    crowding_flag boolean,
    direction character varying(8),
    computed_at timestamp with time zone DEFAULT now()
);


--
-- Name: positioning_signals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.positioning_signals_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: positioning_signals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.positioning_signals_id_seq OWNED BY public.positioning_signals.id;


--
-- Name: regime_snapshots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.regime_snapshots (
    id integer NOT NULL,
    date date,
    growth_pulse character varying(20),
    credit_stress character varying(20),
    real_yield character varying(20),
    dollar_strength character varying(20),
    rates_vol character varying(20),
    equity_vol character varying(20),
    curve_shape character varying(20),
    fingerprint text,
    computed_at timestamp with time zone DEFAULT now(),
    growth_pulse_pct_90d smallint,
    growth_pulse_pct_756d smallint,
    credit_stress_pct_90d smallint,
    credit_stress_pct_756d smallint,
    real_yield_pct_90d smallint,
    real_yield_pct_756d smallint,
    dollar_strength_pct_90d smallint,
    dollar_strength_pct_756d smallint,
    rates_vol_pct_90d smallint,
    rates_vol_pct_756d smallint,
    equity_vol_pct_90d smallint,
    equity_vol_pct_756d smallint,
    curve_shape_pct_90d smallint,
    curve_shape_pct_756d smallint
);


--
-- Name: regime_snapshots_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.regime_snapshots_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: regime_snapshots_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.regime_snapshots_id_seq OWNED BY public.regime_snapshots.id;


--
-- Name: research_theses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.research_theses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    title text DEFAULT 'Untitled Thesis'::text NOT NULL,
    content_html text DEFAULT ''::text NOT NULL,
    tags text[] DEFAULT '{}'::text[] NOT NULL,
    status text DEFAULT 'draft'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    last_auto_saved timestamp with time zone,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    canvas_layout jsonb,
    CONSTRAINT research_theses_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'active'::text, 'archived'::text])))
);


--
-- Name: research_thesis_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.research_thesis_versions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    thesis_id uuid NOT NULL,
    version_number integer NOT NULL,
    version_label text,
    content_html text NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    tags text[] DEFAULT '{}'::text[] NOT NULL,
    status text DEFAULT 'draft'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by text DEFAULT 'user'::text,
    is_auto_save boolean DEFAULT false NOT NULL,
    canvas_layout jsonb
);


--
-- Name: theses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.theses (
    id integer NOT NULL,
    thesis_id character varying(16) NOT NULL,
    generated_at timestamp with time zone NOT NULL,
    theme character varying(128),
    hypothesis text,
    full_doc text,
    instruments jsonb,
    signals_used jsonb,
    confidence double precision,
    status character varying(16),
    outcome character varying(16),
    closed_at timestamp with time zone,
    notes text
);


--
-- Name: theses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.theses_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: theses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.theses_id_seq OWNED BY public.theses.id;


--
-- Name: thesis_outcome_paths; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.thesis_outcome_paths (
    id integer NOT NULL,
    thesis_id uuid NOT NULL,
    series_id character varying(50) NOT NULL,
    predicted_move_pct double precision,
    predicted_direction character varying(10),
    horizon_days integer,
    thesis_created_at timestamp with time zone,
    current_move_pct double precision,
    max_favourable_pct double precision,
    max_adverse_pct double precision,
    correct_at_30pct boolean,
    correct_at_60pct boolean,
    correct_at_100pct boolean,
    target_reached boolean DEFAULT false,
    target_reached_at timestamp with time zone,
    status character varying(20) DEFAULT 'active'::character varying,
    last_updated timestamp with time zone DEFAULT now()
);


--
-- Name: thesis_outcome_paths_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.thesis_outcome_paths_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: thesis_outcome_paths_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.thesis_outcome_paths_id_seq OWNED BY public.thesis_outcome_paths.id;


--
-- Name: thesis_track_record; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.thesis_track_record (
    id integer NOT NULL,
    computed_at timestamp with time zone DEFAULT now(),
    total_theses_tracked integer DEFAULT 0,
    total_variables_tracked integer DEFAULT 0,
    direction_acc_30pct double precision,
    direction_acc_60pct double precision,
    direction_acc_100pct double precision,
    avg_magnitude_ratio double precision,
    magnitude_ratio_p25 double precision,
    magnitude_ratio_p75 double precision,
    by_asset_class jsonb,
    by_focal_series jsonb
);


--
-- Name: thesis_track_record_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.thesis_track_record_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: thesis_track_record_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.thesis_track_record_id_seq OWNED BY public.thesis_track_record.id;


--
-- Name: thesis_variable_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.thesis_variable_history (
    id integer NOT NULL,
    thesis_id uuid,
    focal_series_id character varying(50) NOT NULL,
    target_series_id character varying(50) NOT NULL,
    stance character varying(20) NOT NULL,
    regime_fingerprint text,
    addressed_at timestamp with time zone DEFAULT now()
);


--
-- Name: thesis_variable_history_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.thesis_variable_history_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: thesis_variable_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.thesis_variable_history_id_seq OWNED BY public.thesis_variable_history.id;


--
-- Name: anomalies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.anomalies ALTER COLUMN id SET DEFAULT nextval('public.anomalies_id_seq'::regclass);


--
-- Name: articles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.articles ALTER COLUMN id SET DEFAULT nextval('public.articles_id_seq'::regclass);


--
-- Name: beta_metadata id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.beta_metadata ALTER COLUMN id SET DEFAULT nextval('public.beta_metadata_id_seq'::regclass);


--
-- Name: correlations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.correlations ALTER COLUMN id SET DEFAULT nextval('public.correlations_id_seq'::regclass);


--
-- Name: daily_signals id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_signals ALTER COLUMN id SET DEFAULT nextval('public.daily_signals_id_seq'::regclass);


--
-- Name: market_data id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.market_data ALTER COLUMN id SET DEFAULT nextval('public.market_data_id_seq'::regclass);


--
-- Name: pipeline_errors id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pipeline_errors ALTER COLUMN id SET DEFAULT nextval('public.pipeline_errors_id_seq'::regclass);


--
-- Name: positioning_signals id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.positioning_signals ALTER COLUMN id SET DEFAULT nextval('public.positioning_signals_id_seq'::regclass);


--
-- Name: regime_snapshots id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regime_snapshots ALTER COLUMN id SET DEFAULT nextval('public.regime_snapshots_id_seq'::regclass);


--
-- Name: theses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.theses ALTER COLUMN id SET DEFAULT nextval('public.theses_id_seq'::regclass);


--
-- Name: thesis_outcome_paths id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.thesis_outcome_paths ALTER COLUMN id SET DEFAULT nextval('public.thesis_outcome_paths_id_seq'::regclass);


--
-- Name: thesis_track_record id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.thesis_track_record ALTER COLUMN id SET DEFAULT nextval('public.thesis_track_record_id_seq'::regclass);


--
-- Name: thesis_variable_history id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.thesis_variable_history ALTER COLUMN id SET DEFAULT nextval('public.thesis_variable_history_id_seq'::regclass);


--
-- Data for Name: anomalies; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.anomalies (id, detected_at, anomaly_type, topic, series_id, severity, description, resolved) FROM stdin;
\.


--
-- Data for Name: articles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.articles (id, source_id, url, title, body_text, published_at, ingested_at, entities, topics, sentiment, sentiment_conf, processed) FROM stdin;
58	fed_speeches_rss	https://www.federalreserve.gov/newsevents/speech/jefferson20260206a.htm	Jefferson, Economic Outlook and Supply-Side (Dis)Inflation Dynamics	Speech At the Brookings Institution, Washington, D.C.	2026-02-06 17:00:00+00	2026-03-09 18:13:19.356245+00	{"banks": [], "people": [], "companies": ["Jefferson, Economic Outlook", "the Brookings Institution"], "countries": ["Washington", "D.C."]}	{"hawkish": 0.3551, "inflation": 0.9806, "commodities": 0.6535}	0	0.9155189394950867	t
74	bis_papers_rss	https://www.bis.org/press/p251203.htm	Basel Committee finds the United Kingdom largely compliant with its Net Stable Funding Ratio standard and its large exposures framework		\N	2026-03-09 18:13:19.356245+00	{"banks": [], "people": [], "companies": ["Basel Committee"], "countries": ["the United Kingdom"]}	{"UK": 0.9968, "banking": 0.4442, "technology": 0.3816}	0.786462128162384	0.786462128162384	t
75	bis_papers_rss	https://www.bis.org/press/p251127.htm	Basel Committee publishes more details on the 2025 assessment of global systemically important banks	Basel Committee provides additional information regarding the 2025 G-SIB assessment.\nFurther details include global denominators and individual bank indicators.\nThe release accompanies the Financial Stability Board's updated G-SIB list.	\N	2026-03-09 18:13:19.356245+00	{"banks": [], "people": [], "companies": ["Basel Committee", "the Financial Stability Board's"], "countries": []}	{"UK": 0.3574, "Global": 0.9006, "Germany": 0.391, "banking": 0.8534, "boe_policy": 0.3973}	0	0.9448146820068359	t
101	bis_papers_rss	https://www.bis.org/press/p260309.htm	Governors and Heads of Supervision welcome progress to implement Basel III and discuss elements of the Basel Committee's work programme		\N	2026-03-09 18:34:01.261281+00	{"banks": [], "people": ["Basel III"], "companies": ["Heads of Supervision", "the Basel Committee's"], "countries": []}	{"Germany": 0.6899}	0	0.8403315544128418	t
60	fed_speeches_rss	https://www.federalreserve.gov/newsevents/speech/bowman20260130a.htm	Bowman, Outlook for the Economy and Monetary Policy	Speech At the SW Graduate School of Banking at SMU Cox: 161st Assembly for Bank Directors, Oahu, Hawaii	2026-01-30 22:00:00+00	2026-03-09 18:13:19.356245+00	{"banks": ["the SW Graduate School of Banking", "SMU Cox: 161st Assembly for Bank Directors"], "people": ["Oahu"], "companies": ["Bowman, Outlook for the Economy and Monetary Policy Speech"], "countries": ["Hawaii"]}	{"growth": 0.3762, "banking": 0.4408, "hawkish": 0.402, "boe_policy": 0.4472}	0	0.925613284111023	t
67	bis_papers_rss	https://www.bis.org/press/p260225.htm	Basel Committee discusses recent market developments and targeted review of cryptoasset standard	Discusses vulnerabilities in government bond-backed repo markets.\nDiscusses progress of a targeted review of the prudential standard for banks' cryptoasset exposures.\nAnnounces date and location of the International Conference of Banking Supervisors.	\N	2026-03-09 18:13:19.356245+00	{"banks": ["the International Conference of Banking Supervisors"], "people": [], "companies": ["Basel Committee", "Discusses"], "countries": []}	\N	0	0.9477856159210205	t
83	bis_papers_rss	https://www.bis.org/press/p251002.htm	Basel Committee approves annual G-SIB assessment, enhances the clarity of its grading system for jurisdictional assessments and takes note of the implementation of margin requirements for non-centrally cleared derivatives	Basel Committee approves annual assessment exercise for global systemically important banks. Enhances clarity of its grading system for jurisdictional assessments. Discusses implementation status of margin requirements for non-centrally cleared derivatives.	\N	2026-03-09 18:13:19.356245+00	{"banks": [], "people": [], "companies": ["Basel Committee", "G-SIB"], "countries": []}	{"EU": 0.3833, "IG": 0.6401, "UK": 0.5223, "US": 0.5743, "rates": 0.5656, "Global": 0.9956, "stress": 0.4505, "Germany": 0.7839, "banking": 0.9794, "recession": 0.3611, "volatility": 0.4947}	0.6932999491691589	0.6932999491691589	t
72	bis_papers_rss	https://www.bis.org/press/p251210.htm	Basel Committee publishes principles for the sound management of third-party risk	The Basel Committee has published principles for the sound management of third-party risk in the banking sector.\nThe principles establish a common baseline for banks and supervisors for the sound management of third-party risk.\nThe Committee will continue to monitor developments related to the digitalisation of finance and financial technology from a prudential perspective.	\N	2026-03-09 18:13:19.356245+00	{"banks": [], "people": [], "companies": ["Basel Committee", "The Basel Committee", "Committee"], "countries": []}	{"banking": 0.8955, "technology": 0.6798}	0	0.8881244659423828	t
85	bis_papers_rss	https://www.bis.org/press/p250710.htm	Basel Committee shares report on interconnections between banks  and non-bank financial intermediaries	The report reflects the findings of an analysis conducted as part of the Committee's forward-looking work to identify and analyse risks and vulnerabilities to the banking system. The report identifies the services banks and non-bank financial intermediaries (NBFIs) provide to each other and the trends shaping the relationship between them. The Committee will continue to monitor and investigate the interconnections between banks and NBFIs with a particular focus on synthetic risk transfers.	\N	2026-03-09 18:13:19.356245+00	{"banks": [], "people": [], "companies": ["Basel Committee", "Committee"], "countries": []}	{"banking": 0.5827}	0	0.9304751753807068	t
76	bis_papers_rss	https://www.bis.org/press/p251125.htm	Tommaso Mancini-Griffoli appointed as Head of the BIS Innovation Hub	Tommaso Mancini-Griffoli, currently Assistant Director, Payments, Currencies, and Infrastructure, at the International Monetary Fund (IMF), has been appointed to head the BIS Innovation Hub. He will join the BIS on 1 March 2026.	\N	2026-03-09 18:13:19.356245+00	{"banks": [], "people": ["Tommaso Mancini-Griffoli"], "companies": ["Currencies", "Infrastructure", "the International Monetary Fund", "the BIS Innovation Hub", "BIS"], "countries": []}	{"infrastructure": 0.867}	0	0.9407919645309448	t
90	bis_papers_rss	https://www.bis.org/press/p250521.htm	Basel Committee continues to prioritise Basel III implementation, progresses work to strengthen supervisory effectiveness and discusses finalisation of principles on third-party risks	Basel Committee continues to prioritise the full and consistent implementation of Basel III. Progresses work to strengthen supervisory effectiveness based on the lessons learned from the 2023 banking turmoil. Aims to finalise principles for the sound management of third-party risk in the banking sector by the end of 2025.	\N	2026-03-09 18:13:19.356245+00	{"banks": [], "people": [], "companies": ["Basel Committee", "Basel III"], "countries": []}	{"Germany": 0.5734, "banking": 0.6708}	0.6375085115432739	0.6375085115432739	t
99	reuters_markets_rss	https://www.marketwatch.com/story/final-s-p-u-s-manufacturing-index-is-52-2-in-february-vs-initial-51-5-180b7107?mod=mw_rss_realtimeheadlines	Final S&P U.S. manufacturing index is 52.2 in February vs. initial 51.5		2024-03-01 14:47:00+00	2026-03-09 18:13:19.356245+00	{"banks": [], "people": [], "companies": [], "countries": ["U.S."]}	{"US": 0.9949, "growth": 0.5831, "hawkish": 0.4273, "volatility": 0.5943}	-0.8123130202293396	0.8123130202293396	t
68	bis_papers_rss	https://www.bis.org/press/p260217.htm	Basel Committee publishes analysis of synthetic risk transfers	The Basel Committee on Banking Supervision today published a report on synthetic risk transfer (SRT) transactions. The economic importance of SRT markets has grown rapidly over the last decade and they have become an important source of capital relief for corporate credit risk.	\N	2026-03-09 18:13:19.356245+00	{"banks": ["The Basel Committee on Banking Supervision"], "people": [], "companies": ["Basel Committee", "SRT"], "countries": []}	{"growth": 0.8355, "Germany": 0.4491, "banking": 0.6376}	0	0.6292808055877686	t
69	bis_papers_rss	https://www.bis.org/press/p260209.htm	Statement by Pablo Hernández de Cos, BIS General Manager, on François Villeroy de Galhau	François Villeroy de Galhau, Governor of the Bank of France, today announced his decision to leave the Bank of France at the beginning of June to become President of the Fondation Apprentis d'Auteuil. Accordingly, he will step down from his position as Chair of the BIS Board of Directors.	\N	2026-03-09 18:13:19.356245+00	{"banks": ["the Bank of France"], "people": ["Pablo Hernández de Cos", "François Villeroy de Galhau", "Villeroy de Galhau"], "companies": ["BIS General", "Fondation Apprentis d'Auteuil", "the BIS Board of Directors"], "countries": []}	{"pivot": 0.7266, "stress": 0.7204, "banking": 0.4357, "risk_on": 0.4932, "risk_off": 0.4452, "volatility": 0.5807}	0	0.6454053521156311	t
71	bis_papers_rss	https://www.bis.org/press/p251212.htm	Global standard-setting bodies publish assessment of margin requirements for non-centrally cleared derivatives	The Basel Committee on Banking Supervision (BCBS) and the International Organization of Securities Commissions (IOSCO) today published a report that reviews the implementation of margin requirements for non-centrally cleared derivatives.	\N	2026-03-09 18:13:19.356245+00	{"banks": ["The Basel Committee on Banking Supervision"], "people": [], "companies": ["the International Organization of Securities Commissions", "IOSCO"], "countries": []}	{"Global": 0.9753, "banking": 0.659}	0	0.9268584847450256	t
64	fed_speeches_rss	https://www.federalreserve.gov/newsevents/speech/miran20260114a.htm	Miran, Regulations, the Supply Side, and Monetary Policy	Speech At the Delphi Economic Forum, National Gallery – Alexandros Soutsos Museum,  Athens, Greece	2026-01-14 15:30:00+00	2026-03-09 18:13:19.356245+00	{"banks": [], "people": [], "companies": ["Miran, Regulations", "the Delphi Economic Forum", "National Gallery"], "countries": ["Athens", "Greece"]}	\N	0	0.9213756918907166	t
70	bis_papers_rss	https://www.bis.org/press/p260115.htm	BIS statement of commitment to the FX Global Code	The Bank for International Settlements has reviewed the content of the FX Global Code and acknowledges that the Code represents a set of principles generally recognised as good practice in the wholesale foreign exchange (FX) market.	\N	2026-03-09 18:13:19.356245+00	{"banks": [], "people": [], "companies": ["BIS", "FX"], "countries": []}	{"Global": 0.946, "banking": 0.5335}	0	0.8403452038764954	t
92	reuters_markets_rss	https://www.marketwatch.com/story/bank-of-england-decision-on-thursday-will-be-at-12-02-p-m-local-time-instead-of-12-p-m-due-to-ve-day-two-minutes-of-silence-1f6bed66?mod=mw_rss_realtimeheadlines	Bank of England decision on Thursday will be at 12:02 p.m. local time instead of 12 p.m., due to VE Day’s two minutes of silence		2025-05-06 12:59:00+01	2026-03-09 18:13:19.356245+00	{"banks": ["Bank of England"], "people": [], "companies": [], "countries": []}	{"EM": 0.3839, "UK": 0.8919, "pivot": 0.5698, "stress": 0.5647, "banking": 0.9866, "risk_on": 0.3798, "ECB_policy": 0.407, "volatility": 0.617}	0	0.6220956444740295	t
93	reuters_markets_rss	https://www.marketwatch.com/story/swiss-national-bank-cuts-interest-rates-by-a-half-point-to-0-5-ed1fce78?mod=mw_rss_realtimeheadlines	Swiss National Bank cuts interest rates by a half point to 0.5%		2024-12-12 08:32:00+00	2026-03-09 18:13:19.356245+00	{"banks": ["Swiss National Bank"], "people": [], "companies": [], "countries": []}	{"HY": 0.3538, "rates": 0.9906, "dovish": 0.5409, "banking": 0.9948, "hawkish": 0.7049, "risk_on": 0.5145, "risk_off": 0.5062, "inflation": 0.4387, "liquidity": 0.4855, "boe_policy": 0.7204, "fed_policy": 0.5188, "bank_lending": 0.7709, "credit_cycle": 0.4744, "default_risk": 0.3949, "fiscal_policy": 0.5125}	-0.7310971021652222	0.7310971021652222	t
95	reuters_markets_rss	https://www.marketwatch.com/story/germany-flash-manufacturing-pmi-rises-to-4-month-high-of-43-2-b9e50a64?mod=mw_rss_realtimeheadlines	Germany flash manufacturing PMI rises to 4-month high of 43.2		2024-11-22 08:34:00+00	2026-03-09 18:13:19.356245+00	{"banks": [], "people": [], "companies": ["PMI"], "countries": ["Germany"]}	{"rates": 0.8345, "growth": 0.8173, "Germany": 0.9982, "hawkish": 0.7634, "risk_on": 0.5376, "technology": 0.8826, "volatility": 0.4889}	0.923755407333374	0.923755407333374	t
96	reuters_markets_rss	https://www.marketwatch.com/story/germany-flash-services-pmi-falls-to-9-month-low-of-49-4-5e5d2763?mod=mw_rss_realtimeheadlines	Germany flash services PMI falls to 9-month low of 49.4		2024-11-22 08:34:00+00	2026-03-09 18:13:19.356245+00	{"banks": [], "people": [], "companies": ["PMI"], "countries": ["Germany"]}	{"rates": 0.9304, "stress": 0.5328, "Germany": 0.9974, "risk_on": 0.5622, "spreads": 0.406, "risk_off": 0.3797, "contagion": 0.3719, "liquidity": 0.4794, "technology": 0.8001, "volatility": 0.7811}	-0.971407949924469	0.971407949924469	t
84	bis_papers_rss	https://www.bis.org/press/p250930.htm	Global FX trading hits $9.6 trillion per day in April 2025 and OTC interest rate derivatives surge to $7.9 trillion: Triennial Survey	The 2025 Triennial Central Bank Survey of foreign exchange (FX) and over-the-counter (OTC) interest rate derivatives markets activity shows trading in FX markets reached $9.6 trillion per day in April 2025, up 28% from 2022. Trading of OTC interest rate derivatives rose 59% to $7.9 trillion per day.	\N	2026-03-09 18:13:19.356245+00	{"banks": ["Triennial Central Bank Survey"], "people": [], "companies": ["FX"], "countries": []}	{"rates": 0.916, "Global": 0.9909, "growth": 0.9664, "stress": 0.5252, "hawkish": 0.4432, "risk_on": 0.3681, "inflation": 0.4213, "liquidity": 0.3863, "volatility": 0.6554}	0.9536610841751099	0.9536610841751099	t
55	fed_speeches_rss	https://www.federalreserve.gov/newsevents/speech/bowman20260219a.htm	Bowman, Opening Remarks	Speech At the Federal Reserve Bank of Atlanta 2026 Banking Outlook Conference: The Next Horizon in Banking, Atlanta, Georgia (via pre-recorded video)	2026-02-19 13:30:00+00	2026-03-09 18:13:19.356245+00	{"banks": ["the Federal Reserve Bank of Atlanta 2026 Banking Outlook Conference: The Next Horizon"], "people": [], "companies": ["Bowman, Opening Remarks Speech"], "countries": ["Banking", "Atlanta", "Georgia"]}	{"rates": 0.6756, "banking": 0.9648, "hawkish": 0.5586}	0	0.9357763528823853	t
56	fed_speeches_rss	https://www.federalreserve.gov/newsevents/speech/barr20260217a.htm	Barr, What Will Artificial Intelligence Mean for the Labor Market and the Economy?	Speech At the New York Association for Business Economics, New York, New York	2026-02-17 17:45:00+00	2026-03-09 18:13:19.356245+00	{"banks": [], "people": ["Barr"], "companies": ["the New York Association for Business Economics"], "countries": ["New York"]}	{"hawkish": 0.4204, "technology": 0.7603, "labour_market": 0.5874}	0	0.9114558696746826	t
73	bis_papers_rss	https://www.bis.org/press/p251205.htm	Basel Committee consults on standard format for machine-readable disclosures	The Basel Committee has published a consultation on a standard format for machine-readable disclosures by banks.\nThe proposed standard format would make existing disclosure by banks more accessible and easier to aggregate.\nComments on the proposals are requested by 5 March 2026.	\N	2026-03-09 18:13:19.356245+00	{"banks": [], "people": [], "companies": ["Basel Committee", "The Basel Committee"], "countries": []}	{"Germany": 0.3891, "banking": 0.8107}	0	0.8946112990379333	t
57	fed_speeches_rss	https://www.federalreserve.gov/newsevents/speech/bowman20260216a.htm	Bowman, Revitalizing Bank Mortgage Lending, One Step with Basel	Speech At The American Bankers Association 2026 Conference for Community Bankers, Orlando, Florida	2026-02-16 13:25:00+00	2026-03-09 18:13:19.356245+00	{"banks": ["Bowman, Revitalizing Bank Mortgage Lending", "The American Bankers Association 2026 Conference for Community Bankers"], "people": ["Basel Speech"], "companies": [], "countries": ["Orlando", "Florida"]}	{"pivot": 0.3644, "banking": 0.6895, "bank_lending": 0.425}	0	0.8315961360931396	t
61	fed_speeches_rss	https://www.federalreserve.gov/newsevents/speech/waller20260130a.htm	Waller, Statement by Governor Christopher J. Waller	Speech	2026-01-30 14:00:00+00	2026-03-09 18:13:19.356245+00	{"banks": [], "people": ["Christopher J. Waller"], "companies": ["Waller"], "countries": []}	{"stress": 0.5475, "hawkish": 0.6082, "volatility": 0.378, "fiscal_policy": 0.4742}	0	0.9340685606002808	t
81	bis_papers_rss	https://www.bis.org/press/p251023.htm	Basel III risk-based capital ratios increase while leverage ratio and Net Stable Funding Ratio remain stable for large internationally active banks, latest Basel III monitoring exercise shows	Basel III risk-based capital ratios increased in the second half of 2024. Banks' leverage ratio and Net Stable Funding Ratio remain stable while Liquidity Coverage Ratio decreased. Dashboards offer new features to explore results.	\N	2026-03-09 18:13:19.356245+00	{"banks": [], "people": ["Basel III"], "companies": ["Basel III", "Liquidity Coverage Ratio"], "countries": []}	{"Global": 0.3851, "banking": 0.7412, "liquidity": 0.4279}	0	0.4783315658569336	t
62	fed_speeches_rss	https://www.federalreserve.gov/newsevents/speech/jefferson20260116a.htm	Jefferson, Economic Outlook and Monetary Policy Implementation	Speech At the American Institute for Economic Research, Shadow Open Market Committee, and Florida Atlantic University Conference, Boca Raton, Florida	2026-01-16 20:30:00+00	2026-03-09 18:13:19.356245+00	{"banks": [], "people": ["Implementation Speech"], "companies": ["Jefferson, Economic Outlook", "the American Institute for Economic Research", "Shadow Open Market Committee", "Florida Atlantic University Conference, Boca Raton"], "countries": ["Florida"]}	{"US": 0.389, "hawkish": 0.4669}	0	0.9011746048927307	t
65	fed_speeches_rss	https://www.federalreserve.gov/newsevents/speech/powell20260111a.htm	Powell, Statement from Federal Reserve Chair Jerome H. Powell	Speech	2026-01-12 00:30:00+00	2026-03-09 18:13:19.356245+00	{"banks": ["Federal Reserve"], "people": ["Jerome H. Powell Speech"], "companies": ["Powell, Statement from"], "countries": []}	{"US": 0.6054, "rates": 0.7113, "stress": 0.4659, "hawkish": 0.8041}	0	0.9231438040733337	t
66	bis_papers_rss	https://www.bis.org/press/p260226.htm	Basel Committee issues a consolidated version of its guidelines	The Basel Committee has published a consultation on a consolidated version of its guidelines and sound practices. The consolidated version aims to improve accessibility and substantially streamline guidance materials. Comments on the consultation are requested by 26 June 2026.	\N	2026-03-09 18:13:19.356245+00	{"banks": [], "people": [], "companies": ["Basel Committee", "The Basel Committee"], "countries": []}	{"Germany": 0.4989}	0	0.8196964859962463	t
77	bis_papers_rss	https://www.bis.org/press/p251119.htm	Basel Committee continues to prioritise Basel III implementation, approves final principles on third-party risks and agrees to expedite targeted review of cryptoasset standard	The Basel Committee on Banking Supervision met in Mexico City on 18 and 19 November 2025 to discuss a range of initiatives. It prioritises the full implementation of Basel III, approved third-party risk principles and will review elements of its cryptoasset standard.	\N	2026-03-09 18:13:19.356245+00	{"banks": ["The Basel Committee on Banking Supervision"], "people": [], "companies": ["Basel Committee", "Basel III"], "countries": ["Mexico City"]}	{"banking": 0.9301, "risk_on": 0.4477}	0	0.8882112503051758	t
78	bis_papers_rss	https://www.bis.org/press/p251112.htm	Appointment: BIS Global Economy Meeting and Economic Consultative Committee Chair	The Board of Directors of the Bank for International Settlements (BIS) has today announced that Christine Lagarde, President of the European Central Bank, will succeed Jerome H Powell, Chair of the Board of Governors of the Federal Reserve System, as Chair of the Global Economy Meeting (GEM) and Economic Consultative Committee (ECC) from May 2026.	\N	2026-03-09 18:13:19.356245+00	{"banks": ["the Bank for International Settlements", "the European Central Bank", "the Federal Reserve System"], "people": ["Christine Lagarde", "Jerome H Powell"], "companies": ["BIS", "the Board of Governors", "GEM", "Economic Consultative Committee"], "countries": []}	{"EM": 0.5522, "Global": 0.8844}	0	0.9332563281059265	t
79	bis_papers_rss	https://www.bis.org/press/p251111.htm	BIS, South African Reserve Bank announce winners of G20 TechSprint	The Bank for International Settlements (BIS) and the South African Reserve Bank (SARB), under the South African G20 Presidency, today announced the winners of the G20 TechSprint 2025 challenge on trust and integrity in finance.	\N	2026-03-09 18:13:19.356245+00	{"banks": ["South African Reserve Bank", "G20 TechSprint The Bank for International Settlements", "the South African Reserve Bank"], "people": [], "companies": ["BIS", "the South African G20", "G20"], "countries": []}	\N	0.6143998503684998	0.6143998503684998	t
82	bis_papers_rss	https://www.bis.org/press/p251003.htm	Basel Committee reports further progress on Basel III implementation	Over the past 12 months, the final Basel III standards came into effect in more than 40% of the Basel Committee's 27 member jurisdictions. The revised credit risk and operational risk standards as well as the output floor are now in effect in around 80% of member jurisdictions. The Committee will continue to closely monitor and assess the full and consistent implementation of Basel III standards.	\N	2026-03-09 18:13:19.356245+00	{"banks": [], "people": [], "companies": ["Basel Committee", "Basel III", "the Basel Committee's", "Committee"], "countries": []}	{"Germany": 0.4826}	0	0.6519371867179871	t
88	bis_papers_rss	https://www.bis.org/press/p250613.htm	Basel Committee publishes framework for voluntary disclosure of climate-related financial risks	The Basel Committee has published a voluntary framework for disclosing climate-related financial risks for jurisdictions to consider.\nThe framework incorporates flexibility to account for evolving climate-related data.\nThe Committee will monitor relevant developments, including implementation of other reporting frameworks and disclosure practices by internationally active banks.	\N	2026-03-09 18:13:19.356245+00	{"banks": [], "people": [], "companies": ["Basel Committee", "The Basel Committee", "Committee"], "countries": []}	{"EU": 0.3618, "UK": 0.5658, "US": 0.4057, "China": 0.3791, "Germany": 0.5951, "boe_policy": 0.3953}	0	0.896589994430542	t
100	reuters_markets_rss	https://www.marketwatch.com/story/duolingo-started-at-buy-with-222-price-target-at-seaport-f762126a?mod=mw_rss_realtimeheadlines	Duolingo started at buy with $222 price target at Seaport		2024-02-27 12:40:00+00	2026-03-09 18:13:19.356245+00	{"banks": [], "people": [], "companies": ["Duolingo", "Seaport"], "countries": []}	{"US": 0.5012, "rates": 0.4581, "hawkish": 0.4022, "risk_on": 0.4388, "liquidity": 0.6292, "technology": 0.9501, "volatility": 0.4287, "commodities": 0.5716}	0.5159095525741577	0.5159095525741577	t
53	fed_speeches_rss	https://www.federalreserve.gov/newsevents/speech/waller20260224a.htm	Waller, Operationalizing AI at the Federal Reserve	Speech At the Federal Reserve Bank of Boston 2026 Technology-Enabled Disruption Conference: Shaping the Future of Finance and Payments, Boston, Massachusetts (via webcast)	2026-02-24 14:15:00+00	2026-03-09 18:13:19.356245+00	{"banks": ["the Federal Reserve Speech", "the Federal Reserve Bank of Boston 2026 Technology-Enabled Disruption Conference: Shaping the Future of Finance and Payments"], "people": [], "companies": ["Waller, Operationalizing AI"], "countries": ["Boston", "Massachusetts"]}	{"US": 0.7466, "hawkish": 0.5123, "technology": 0.9903}	0	0.9036188125610352	t
54	fed_speeches_rss	https://www.federalreserve.gov/newsevents/speech/waller20260223a.htm	Waller, Labor Market Data: Signal or Noise?	Speech At The Great Realignment: Navigating AI, Demographic and Geoeconomic Change, 42nd Annual NABE Economic Policy Conference, The National Association for Business Economics, Washington, D.C.	2026-02-23 13:00:00+00	2026-03-09 18:13:19.356245+00	{"banks": [], "people": ["Noise", "Demographic", "Geoeconomic Change"], "companies": ["Waller", "Labor Market Data: Signal", "The National Association for Business Economics"], "countries": ["Washington", "D.C."]}	{"pivot": 0.3852, "labour_market": 0.5999}	0	0.9203493595123291	t
87	bis_papers_rss	https://www.bis.org/press/p250624.htm	Next-generation monetary and financial system takes shape, based on a tokenised unified ledger: BIS	Building on the proposal for a unified ledger, the "trilogy" of tokenised central bank reserves, commercial bank money and government bonds is the next logical step to deliver profound change for the financial system.\nTokenisation can enhance efficiency and open new possibilities in cross-border payments, securities markets and beyond, while maintaining the key principles of sound money: singleness, elasticity and integrity.\nStablecoins as a form of sound money fall short, and without regulation pose a risk to financial stability and monetary sovereignty.	\N	2026-03-09 18:13:19.356245+00	{"banks": [], "people": [], "companies": ["BIS Building"], "countries": []}	\N	0	0.6801721453666687	t
97	reuters_markets_rss	https://www.marketwatch.com/story/powell-says-labor-market-not-a-source-of-significant-inflation-pressure-cc3b1297?mod=mw_rss_realtimeheadlines	Powell says labor market not a source of significant inflation pressure		2024-07-31 19:48:00+01	2026-03-09 18:13:19.356245+00	{"banks": [], "people": ["Powell"], "companies": [], "countries": []}	{"hawkish": 0.4294, "boe_policy": 0.3527, "labour_market": 0.6964}	0	0.5824132561683655	t
98	reuters_markets_rss	https://www.marketwatch.com/story/feds-powell-says-rate-cut-on-the-table-as-soon-as-september-f3f7c8f2?mod=mw_rss_realtimeheadlines	Fed’s Powell says rate cut ‘on the table’ as soon as September		2024-07-31 19:41:00+01	2026-03-09 18:13:19.356245+00	{"banks": ["Fed"], "people": [], "companies": [], "countries": []}	{"US": 0.7671, "rates": 0.9892, "banking": 0.4022, "hawkish": 0.6466, "boe_policy": 0.5179, "fed_policy": 0.899, "bank_lending": 0.4524}	0	0.6025389432907104	t
86	bis_papers_rss	https://www.bis.org/press/p250629.htm	Trade tensions and uncertainty cloud global economy: BIS	Heightened policy uncertainty and fraying trade ties have weakened the growth outlook, while existing vulnerabilities compound the risks and make economies more prone to inflation pressures.\nWhile central banks focus on price stability, governments must support structural reforms and manage public finances sustainably to foster growth to meet future needs.\nThe increased role of non-banks, including a shift towards financing public debt, brings stronger international transmission of financial conditions and also financial stability risks.	\N	2026-03-09 18:13:19.356245+00	{"banks": [], "people": [], "companies": ["BIS Heightened"], "countries": []}	{"Global": 0.9492, "growth": 0.7958, "stress": 0.8186, "banking": 0.4965, "risk_on": 0.4728, "inflation": 0.9649, "boe_policy": 0.3714, "fed_policy": 0.3639, "volatility": 0.888, "fiscal_policy": 0.4471}	0.45478740334510803	0.45478740334510803	t
89	bis_papers_rss	https://www.bis.org/press/p250522.htm	Statement on the appointment of Cecilia Skingsley as County Governor of Stockholm	The Swedish government today announced that it has appointed Cecilia Skingsley as County Governor of the County Administrative Board of Stockholm, effective 15 June 2025.	\N	2026-03-09 18:13:19.356245+00	{"banks": [], "people": [], "companies": ["the County Administrative Board of Stockholm"], "countries": ["Cecilia", "Stockholm"]}	\N	0	0.9175384640693665	t
52	fed_speeches_rss	https://www.federalreserve.gov/newsevents/speech/cook20260224a.htm	Cook, Opening Remarks for the “AI and Productivity across the Economy” Panel	Speech At “The Great Realignment: Navigating AI, Demographic, and Geoeconomic Shifts,” 42nd Annual NABE Economic Policy Conference, Washington, D.C.	2026-02-24 14:30:00+00	2026-03-09 18:13:19.356245+00	{"banks": [], "people": ["Cook", "Opening Remarks", "Demographic", "Geoeconomic Shifts"], "companies": [], "countries": ["Washington", "D.C."]}	{"technology": 0.7192}	0	0.885619580745697	t
59	fed_speeches_rss	https://www.federalreserve.gov/newsevents/speech/cook20260204a.htm	Cook, Economic Outlook	Speech At the Economic Club of Miami, Miami, Florida	2026-02-04 23:30:00+00	2026-03-09 18:13:19.356245+00	{"banks": [], "people": [], "companies": ["Cook, Economic Outlook Speech", "the Economic Club"], "countries": ["Miami", "Florida"]}	{"EM": 0.4784, "growth": 0.4563}	0	0.9029395580291748	t
91	reuters_markets_rss	https://www.marketwatch.com/story/elon-musk-in-a-post-on-x-says-some-of-his-trump-posts-went-too-far-and-that-he-regrets-them-90e73a6a?mod=mw_rss_realtimeheadlines	Elon Musk in a post on X says some of his Trump posts ‘went too far’ and that he regrets them		2025-06-11 08:09:00+01	2026-03-09 18:13:19.356245+00	{"banks": [], "people": ["Elon Musk"], "companies": ["Trump"], "countries": []}	{"US": 0.7677, "dovish": 0.4332, "stress": 0.4645, "risk_on": 0.4282, "volatility": 0.6521, "real_estate": 0.494}	-0.8888047933578491	0.8888047933578491	t
63	fed_speeches_rss	https://www.federalreserve.gov/newsevents/speech/bowman20260116a.htm	Bowman, Outlook for the Economy and Monetary Policy	Speech At Outlook 26:  The New England Economic Forum, Foxborough, Massachusetts	2026-01-16 16:00:00+00	2026-03-09 18:13:19.356245+00	{"banks": [], "people": [], "companies": ["Bowman, Outlook for the Economy and Monetary Policy", "The New England Economic Forum"], "countries": ["Massachusetts"]}	{"hawkish": 0.4445, "boe_policy": 0.4939}	0	0.9024722576141357	t
94	reuters_markets_rss	https://www.marketwatch.com/story/dollar-jumps-0-5-to-0-8890-francs-047c6b4d?mod=mw_rss_realtimeheadlines	Dollar jumps 0.5% to 0.8890 francs		2024-12-12 08:32:00+00	2026-03-09 18:13:19.356245+00	{"banks": [], "people": [], "companies": [], "countries": []}	{"rates": 0.6416, "Global": 0.584, "growth": 0.7284, "Germany": 0.4426, "banking": 0.6423, "hawkish": 0.5639, "risk_on": 0.6276, "risk_off": 0.3907, "contagion": 0.3815, "inflation": 0.8247, "liquidity": 0.8973, "volatility": 0.8632, "commodities": 0.9779, "bank_lending": 0.5992, "credit_cycle": 0.5038, "default_risk": 0.5357, "fiscal_policy": 0.5173}	0.8932120203971863	0.8932120203971863	t
51	fed_speeches_rss	https://www.federalreserve.gov/newsevents/speech/bowman20260303a.htm	Bowman, Liquidity Resiliency, Financial Stability, and the Role of the Federal Reserve	Speech At The Roundtable on Liquidity and Lender of Last Resort sponsored by the Committee on Capital Markets Regulation, Washington, D.C.	2026-03-03 13:30:00+00	2026-03-09 18:13:19.356245+00	{"banks": ["the Federal Reserve Speech"], "people": [], "companies": ["Bowman, Liquidity Resiliency", "Financial Stability", "The Roundtable on Liquidity and Lender of Last Resort", "the Committee on Capital Markets Regulation"], "countries": ["Washington", "D.C."]}	{"liquidity": 0.9259}	0	0.9002519249916077	t
80	bis_papers_rss	https://www.bis.org/press/p251107.htm	Global standard-setting bodies publish an assessment report and a consultative report to set out guidance on general business risks and general business losses	The BIS Committee on Payments and Market Infrastructures (CPMI) and the International Organization of Securities Commissions (IOSCO) today published an implementation monitoring report on general business risks and a consultative report on financial market infrastructures' (FMIs) management of general business risks and general business losses.	\N	2026-03-09 18:13:19.356245+00	{"banks": [], "people": [], "companies": ["The BIS Committee on Payments and Market Infrastructures", "CPMI", "the International Organization of Securities Commissions", "IOSCO"], "countries": []}	{"Global": 0.9827}	0	0.8938714265823364	t
\.


--
-- Data for Name: beta_metadata; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.beta_metadata (id, base_series_id, target_series_id, optimal_decay, break_date, break_detected, last_computed) FROM stdin;
1	CM.BRENT	CM.COPPER	1	2026-01-26	f	2026-04-05 18:45:53.302614+01
2	CM.BRENT	CM.COPPER_GOLD_RATIO	1	2026-01-26	f	2026-04-05 18:45:53.319705+01
3	CM.BRENT	CM.GOLD	1	2026-01-26	f	2026-04-05 18:45:53.328009+01
4	CM.BRENT	CM.IRON_ORE	1	2026-01-27	t	2026-04-05 18:45:53.336116+01
5	CM.BRENT	CM.NATGAS	1	2026-01-26	f	2026-04-05 18:45:53.346988+01
6	CM.BRENT	CM.SILVER	1	2026-01-26	f	2026-04-05 18:45:53.35584+01
7	CM.BRENT	CM.WHEAT	1	2026-01-27	f	2026-04-05 18:45:53.364887+01
8	CM.BRENT	CM.WTI	1	2026-01-26	f	2026-04-05 18:45:53.37461+01
9	CM.BRENT	CREDIT.HY_OAS	1	2026-01-26	f	2026-04-05 18:45:53.382694+01
10	CM.BRENT	CREDIT.IG_HY_DIFF	1	\N	f	2026-04-05 18:45:53.391738+01
11	CM.BRENT	CREDIT.IG_OAS	1	\N	f	2026-04-05 18:45:53.400066+01
12	CM.BRENT	EQ.AAPL	1	2026-01-26	f	2026-04-05 18:45:53.408527+01
13	CM.BRENT	EQ.ASML	1	2026-01-26	f	2026-04-05 18:45:53.418121+01
14	CM.BRENT	EQ.DAX	1	\N	f	2026-04-05 18:45:53.42767+01
15	CM.BRENT	EQ.EEM	1	2026-01-26	f	2026-04-05 18:45:53.436755+01
16	CM.BRENT	EQ.FTSE	1	\N	f	2026-04-05 18:45:53.446099+01
17	CM.BRENT	EQ.GLD	1	2026-01-26	f	2026-04-05 18:45:53.454766+01
18	CM.BRENT	EQ.HYG	1	2026-01-26	f	2026-04-05 18:45:53.463708+01
19	CM.BRENT	EQ.IEAC	1	2026-01-27	f	2026-04-05 18:45:53.474238+01
20	CM.BRENT	EQ.IHYG	1	2026-01-27	f	2026-04-05 18:45:53.482797+01
21	CM.BRENT	EQ.IWM	1	2026-01-26	f	2026-04-05 18:45:53.492792+01
22	CM.BRENT	EQ.LQD	1	2026-01-26	f	2026-04-05 18:45:53.506635+01
23	CM.BRENT	EQ.LVMH	1	2026-01-26	f	2026-04-05 18:45:53.517003+01
24	CM.BRENT	EQ.MOVE	1	2026-01-26	f	2026-04-05 18:45:53.527533+01
25	CM.BRENT	EQ.NIKKEI	1	\N	f	2026-04-05 18:45:53.537026+01
26	CM.BRENT	EQ.SHEL	1	2026-01-26	f	2026-04-05 18:45:53.545148+01
27	CM.BRENT	EQ.SLV	1	2026-01-26	f	2026-04-05 18:45:53.555555+01
28	CM.BRENT	EQ.SPX	1	2026-01-26	f	2026-04-05 18:45:53.564494+01
29	CM.BRENT	EQ.SPY	1	2026-01-26	f	2026-04-05 18:45:53.574872+01
30	CM.BRENT	EQ.STOXX600	1	\N	f	2026-04-05 18:45:53.585635+01
31	CM.BRENT	EQ.SX7E	1	\N	f	2026-04-05 18:45:53.595693+01
32	CM.BRENT	EQ.VIX	1	2026-01-26	f	2026-04-05 18:45:53.605845+01
33	CM.BRENT	EQ.XLB	1	2026-01-26	f	2026-04-05 18:45:53.613767+01
34	CM.BRENT	EQ.XLE	1	2026-01-26	t	2026-04-05 18:45:53.62551+01
35	CM.BRENT	EQ.XLF	1	2026-01-26	f	2026-04-05 18:45:53.635953+01
36	CM.BRENT	EQ.XLI	1	2026-01-26	f	2026-04-05 18:45:53.645294+01
37	CM.BRENT	EQ.XLK	1	2026-01-26	f	2026-04-05 18:45:53.65704+01
38	CM.BRENT	EQ.XLP	1	2026-01-26	f	2026-04-05 18:45:53.66766+01
39	CM.BRENT	EQ.XLU	1	2026-01-26	f	2026-04-05 18:45:53.678793+01
40	CM.BRENT	EQ.XLV	1	2026-01-26	f	2026-04-05 18:45:53.691348+01
41	CM.BRENT	EQ.XLY	1	2026-01-26	f	2026-04-05 18:45:53.699961+01
42	CM.BRENT	FX.AUDUSD	1	2026-01-26	f	2026-04-05 18:45:53.708435+01
43	CM.BRENT	FX.DXY	1	2026-01-26	f	2026-04-05 18:45:53.718432+01
44	CM.BRENT	FX.EURGBP	1	2026-01-26	f	2026-04-05 18:45:53.728961+01
45	CM.BRENT	FX.EURUSD	1	2026-01-26	f	2026-04-05 18:45:53.740799+01
46	CM.BRENT	FX.GBPUSD	1	2026-01-26	f	2026-04-05 18:45:53.751284+01
47	CM.BRENT	FX.USDCHF	1	2026-01-27	f	2026-04-05 18:45:53.762493+01
48	CM.BRENT	FX.USDJPY	1	2026-01-26	f	2026-04-05 18:45:53.773737+01
49	CM.BRENT	RATES.2S10S	1	2026-01-26	f	2026-04-05 18:45:53.782323+01
50	CM.BRENT	RATES.5S30S	1	\N	f	2026-04-05 18:45:53.793225+01
51	CM.BRENT	RATES.BREAKEVEN	1	2026-01-26	f	2026-04-05 18:45:53.801634+01
52	CM.BRENT	RATES.BREAKEVEN5Y	1	2026-01-27	f	2026-04-05 18:45:53.81259+01
53	CM.BRENT	RATES.REAL_TERM_PREM	1	\N	f	2026-04-05 18:45:53.824841+01
54	CM.BRENT	RATES.REAL10Y	1	2026-01-26	f	2026-04-05 18:45:53.836199+01
55	CM.BRENT	RATES.REAL5Y	1	\N	f	2026-04-05 18:45:53.84607+01
56	CM.BRENT	RATES.US10Y	1	2026-01-26	f	2026-04-05 18:45:53.856691+01
57	CM.BRENT	RATES.US2Y	1	2026-01-26	f	2026-04-05 18:45:53.864965+01
58	CM.BRENT	RATES.US30Y	1	\N	f	2026-04-05 18:45:53.875539+01
59	CM.BRENT	RATES.US3M	1	\N	f	2026-04-05 18:45:53.884984+01
60	CM.BRENT	RATES.US5Y	1	\N	f	2026-04-05 18:45:53.894623+01
\.


--
-- Data for Name: correlations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.correlations (id, topic, series_id, lag_days, correlation, p_value, window_days, computed_at, quality) FROM stdin;
278	US	EQ.SPX	0	NaN	NaN	90	2026-03-12	ok
279	US	EQ.SPX	1	NaN	NaN	90	2026-03-12	ok
280	US	EQ.SPX	3	NaN	NaN	90	2026-03-12	ok
281	US	EQ.SPX	5	NaN	NaN	90	2026-03-12	ok
282	US	EQ.SPX	10	NaN	NaN	90	2026-03-12	ok
283	US	EQ.IWM	0	NaN	NaN	90	2026-03-12	ok
284	US	EQ.IWM	1	NaN	NaN	90	2026-03-12	ok
285	US	EQ.IWM	3	NaN	NaN	90	2026-03-12	ok
286	US	EQ.IWM	5	NaN	NaN	90	2026-03-12	ok
287	US	EQ.IWM	10	NaN	NaN	90	2026-03-12	ok
288	US	EQ.XLY	0	NaN	NaN	90	2026-03-12	ok
289	US	EQ.XLY	1	NaN	NaN	90	2026-03-12	ok
290	US	EQ.XLY	3	NaN	NaN	90	2026-03-12	ok
291	US	EQ.XLY	5	NaN	NaN	90	2026-03-12	ok
292	US	EQ.XLY	10	NaN	NaN	90	2026-03-12	ok
293	US	EQ.SPY	0	NaN	NaN	90	2026-03-12	ok
294	US	EQ.SPY	1	NaN	NaN	90	2026-03-12	ok
295	US	EQ.SPY	3	NaN	NaN	90	2026-03-12	ok
296	US	EQ.SPY	5	NaN	NaN	90	2026-03-12	ok
297	US	EQ.SPY	10	NaN	NaN	90	2026-03-12	ok
298	US	EQ.XLB	0	NaN	NaN	90	2026-03-12	ok
299	US	EQ.XLB	1	NaN	NaN	90	2026-03-12	ok
300	US	EQ.XLB	3	NaN	NaN	90	2026-03-12	ok
301	US	EQ.XLB	5	NaN	NaN	90	2026-03-12	ok
302	US	EQ.XLB	10	NaN	NaN	90	2026-03-12	ok
303	US	EQ.XLI	0	NaN	NaN	90	2026-03-12	ok
304	US	EQ.XLI	1	NaN	NaN	90	2026-03-12	ok
305	US	EQ.XLI	3	NaN	NaN	90	2026-03-12	ok
306	US	EQ.XLI	5	NaN	NaN	90	2026-03-12	ok
307	US	EQ.XLI	10	NaN	NaN	90	2026-03-12	ok
308	US	EQ.XLE	0	NaN	NaN	90	2026-03-12	ok
309	US	EQ.XLE	1	NaN	NaN	90	2026-03-12	ok
310	US	EQ.XLE	3	NaN	NaN	90	2026-03-12	ok
311	US	EQ.XLE	5	NaN	NaN	90	2026-03-12	ok
312	US	EQ.XLE	10	NaN	NaN	90	2026-03-12	ok
313	US	EQ.XLP	0	NaN	NaN	90	2026-03-12	ok
314	US	EQ.XLP	1	NaN	NaN	90	2026-03-12	ok
315	US	EQ.XLP	3	NaN	NaN	90	2026-03-12	ok
316	US	EQ.XLP	5	NaN	NaN	90	2026-03-12	ok
317	US	EQ.XLP	10	NaN	NaN	90	2026-03-12	ok
318	US	EQ.XLF	0	NaN	NaN	90	2026-03-12	ok
319	US	EQ.XLF	1	NaN	NaN	90	2026-03-12	ok
320	US	EQ.XLF	3	NaN	NaN	90	2026-03-12	ok
321	US	EQ.XLF	5	NaN	NaN	90	2026-03-12	ok
322	US	EQ.XLF	10	NaN	NaN	90	2026-03-12	ok
323	US	EQ.XLK	0	NaN	NaN	90	2026-03-12	ok
324	US	EQ.XLK	1	NaN	NaN	90	2026-03-12	ok
325	US	EQ.XLK	3	NaN	NaN	90	2026-03-12	ok
326	US	EQ.XLK	5	NaN	NaN	90	2026-03-12	ok
327	US	EQ.XLK	10	NaN	NaN	90	2026-03-12	ok
328	US	EQ.XLV	0	NaN	NaN	90	2026-03-12	ok
329	US	EQ.XLV	1	NaN	NaN	90	2026-03-12	ok
330	US	EQ.XLV	3	NaN	NaN	90	2026-03-12	ok
331	US	EQ.XLV	5	NaN	NaN	90	2026-03-12	ok
332	US	EQ.XLV	10	NaN	NaN	90	2026-03-12	ok
\.


--
-- Data for Name: daily_signals; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.daily_signals (id, date, topic, article_count, velocity_7d, sentiment_avg, sentiment_std, source_count, divergence_flag, anomaly_flag, data_quality) FROM stdin;
1281	2024-11-22	rates	2	\N	-0.04765254259109497	1.340506418393477	1	f	f	velocity_cold_start
1282	2024-11-22	growth	1	\N	0.923755407333374	0	1	f	f	velocity_cold_start
1283	2024-11-22	Germany	2	\N	-0.04765254259109497	1.340506418393477	1	f	f	velocity_cold_start
1284	2024-11-22	hawkish	1	\N	0.923755407333374	0	1	f	f	velocity_cold_start
1285	2024-11-22	risk_on	2	\N	-0.04765254259109497	1.340506418393477	1	f	f	velocity_cold_start
1286	2024-11-22	technology	2	\N	-0.04765254259109497	1.340506418393477	1	f	f	velocity_cold_start
1287	2024-11-22	volatility	2	\N	-0.04765254259109497	1.340506418393477	1	f	f	velocity_cold_start
1288	2024-11-22	stress	1	\N	-0.971407949924469	0	1	f	f	velocity_cold_start
1289	2024-11-22	spreads	1	\N	-0.971407949924469	0	1	f	f	velocity_cold_start
1290	2024-11-22	risk_off	1	\N	-0.971407949924469	0	1	f	f	velocity_cold_start
1291	2024-11-22	contagion	1	\N	-0.971407949924469	0	1	f	f	velocity_cold_start
1292	2024-11-22	liquidity	1	\N	-0.971407949924469	0	1	f	f	velocity_cold_start
1293	2026-01-12	US	1	\N	0	0	1	f	f	velocity_cold_start
1294	2026-01-12	rates	1	\N	0	0	1	f	f	velocity_cold_start
1295	2026-01-12	stress	1	\N	0	0	1	f	f	velocity_cold_start
1296	2026-01-12	hawkish	1	\N	0	0	1	f	f	velocity_cold_start
1297	2026-03-03	liquidity	1	\N	0	0	1	f	f	velocity_cold_start
1298	2024-03-01	US	1	\N	-0.8123130202293396	0	1	f	f	velocity_cold_start
1299	2024-03-01	growth	1	\N	-0.8123130202293396	0	1	f	f	velocity_cold_start
1300	2024-03-01	hawkish	1	\N	-0.8123130202293396	0	1	f	f	velocity_cold_start
1301	2024-03-01	volatility	1	\N	-0.8123130202293396	0	1	f	f	velocity_cold_start
1302	2025-06-11	US	1	\N	-0.8888047933578491	0	1	f	f	velocity_cold_start
1303	2025-06-11	dovish	1	\N	-0.8888047933578491	0	1	f	f	velocity_cold_start
1304	2025-06-11	stress	1	\N	-0.8888047933578491	0	1	f	f	velocity_cold_start
1305	2025-06-11	risk_on	1	\N	-0.8888047933578491	0	1	f	f	velocity_cold_start
1306	2025-06-11	volatility	1	\N	-0.8888047933578491	0	1	f	f	velocity_cold_start
1307	2025-06-11	real_estate	1	\N	-0.8888047933578491	0	1	f	f	velocity_cold_start
1308	2026-02-17	hawkish	1	\N	0	0	1	f	f	velocity_cold_start
1309	2026-02-17	technology	1	\N	0	0	1	f	f	velocity_cold_start
1310	2026-02-17	labour_market	1	\N	0	0	1	f	f	velocity_cold_start
1311	2026-02-24	US	1	\N	0	0	1	f	f	velocity_cold_start
1312	2026-02-24	hawkish	1	\N	0	0	1	f	f	velocity_cold_start
1313	2026-02-24	technology	2	\N	0	0	1	f	f	velocity_cold_start
1314	2024-07-31	hawkish	2	\N	0	0	1	f	f	velocity_cold_start
1315	2024-07-31	boe_policy	2	\N	0	0	1	f	f	velocity_cold_start
1316	2024-07-31	labour_market	1	\N	0	0	1	f	f	velocity_cold_start
1317	2024-07-31	US	1	\N	0	0	1	f	f	velocity_cold_start
1318	2024-07-31	rates	1	\N	0	0	1	f	f	velocity_cold_start
1319	2024-07-31	banking	1	\N	0	0	1	f	f	velocity_cold_start
1320	2024-07-31	fed_policy	1	\N	0	0	1	f	f	velocity_cold_start
1321	2024-07-31	bank_lending	1	\N	0	0	1	f	f	velocity_cold_start
1322	2026-02-19	rates	1	\N	0	0	1	f	f	velocity_cold_start
1323	2026-02-19	banking	1	\N	0	0	1	f	f	velocity_cold_start
1324	2026-02-19	hawkish	1	\N	0	0	1	f	f	velocity_cold_start
1325	2024-02-27	US	1	\N	0.5159095525741577	0	1	f	f	velocity_cold_start
1326	2024-02-27	rates	1	\N	0.5159095525741577	0	1	f	f	velocity_cold_start
1327	2024-02-27	hawkish	1	\N	0.5159095525741577	0	1	f	f	velocity_cold_start
1328	2024-02-27	risk_on	1	\N	0.5159095525741577	0	1	f	f	velocity_cold_start
1329	2024-02-27	liquidity	1	\N	0.5159095525741577	0	1	f	f	velocity_cold_start
1330	2024-02-27	technology	1	\N	0.5159095525741577	0	1	f	f	velocity_cold_start
1331	2024-02-27	volatility	1	\N	0.5159095525741577	0	1	f	f	velocity_cold_start
1332	2024-02-27	commodities	1	\N	0.5159095525741577	0	1	f	f	velocity_cold_start
1333	2026-01-30	growth	1	\N	0	0	1	f	f	velocity_cold_start
1334	2026-01-30	banking	1	\N	0	0	1	f	f	velocity_cold_start
1335	2026-01-30	hawkish	2	\N	0	0	1	f	f	velocity_cold_start
1336	2026-01-30	boe_policy	1	\N	0	0	1	f	f	velocity_cold_start
1337	2026-01-30	stress	1	\N	0	0	1	f	f	velocity_cold_start
1338	2026-01-30	volatility	1	\N	0	0	1	f	f	velocity_cold_start
1339	2026-01-30	fiscal_policy	1	\N	0	0	1	f	f	velocity_cold_start
1340	2026-02-04	EM	1	\N	0	0	1	f	f	velocity_cold_start
1341	2026-02-04	growth	1	\N	0	0	1	f	f	velocity_cold_start
1342	2025-05-06	EM	1	\N	0	0	1	f	f	velocity_cold_start
1343	2025-05-06	UK	1	\N	0	0	1	f	f	velocity_cold_start
1344	2025-05-06	pivot	1	\N	0	0	1	f	f	velocity_cold_start
1345	2025-05-06	stress	1	\N	0	0	1	f	f	velocity_cold_start
1346	2025-05-06	banking	1	\N	0	0	1	f	f	velocity_cold_start
1347	2025-05-06	risk_on	1	\N	0	0	1	f	f	velocity_cold_start
1348	2025-05-06	ECB_policy	1	\N	0	0	1	f	f	velocity_cold_start
1349	2025-05-06	volatility	1	\N	0	0	1	f	f	velocity_cold_start
1350	2026-02-06	hawkish	1	\N	0	0	1	f	f	velocity_cold_start
1351	2026-02-06	inflation	1	\N	0	0	1	f	f	velocity_cold_start
1352	2026-02-06	commodities	1	\N	0	0	1	f	f	velocity_cold_start
1353	2026-02-23	pivot	1	\N	0	0	1	f	f	velocity_cold_start
1354	2026-02-23	labour_market	1	\N	0	0	1	f	f	velocity_cold_start
1355	2026-02-16	pivot	1	\N	0	0	1	f	f	velocity_cold_start
1356	2026-02-16	banking	1	\N	0	0	1	f	f	velocity_cold_start
1357	2026-02-16	bank_lending	1	\N	0	0	1	f	f	velocity_cold_start
1358	2024-12-12	HY	1	\N	-0.7310971021652222	0	1	f	f	velocity_cold_start
1359	2024-12-12	rates	2	\N	0.1621149182319641	1.1542662977737888	1	f	f	velocity_cold_start
1360	2024-12-12	dovish	1	\N	-0.7310971021652222	0	1	f	f	velocity_cold_start
1361	2024-12-12	banking	2	\N	0.1621149182319641	1.1542662977737888	1	f	f	velocity_cold_start
1362	2024-12-12	hawkish	2	\N	0.1621149182319641	1.1542662977737888	1	f	f	velocity_cold_start
1363	2024-12-12	risk_on	2	\N	0.1621149182319641	1.1542662977737888	1	f	f	velocity_cold_start
1364	2024-12-12	risk_off	2	\N	0.1621149182319641	1.1542662977737888	1	f	f	velocity_cold_start
1365	2024-12-12	inflation	2	\N	0.1621149182319641	1.1542662977737888	1	f	f	velocity_cold_start
1366	2024-12-12	liquidity	2	\N	0.1621149182319641	1.1542662977737888	1	f	f	velocity_cold_start
1367	2024-12-12	boe_policy	1	\N	-0.7310971021652222	0	1	f	f	velocity_cold_start
1368	2024-12-12	fed_policy	1	\N	-0.7310971021652222	0	1	f	f	velocity_cold_start
1369	2024-12-12	bank_lending	2	\N	0.1621149182319641	1.1542662977737888	1	f	f	velocity_cold_start
1370	2024-12-12	credit_cycle	2	\N	0.1621149182319641	1.1542662977737888	1	f	f	velocity_cold_start
1371	2024-12-12	default_risk	2	\N	0.1621149182319641	1.1542662977737888	1	f	f	velocity_cold_start
1372	2024-12-12	fiscal_policy	2	\N	0.1621149182319641	1.1542662977737888	1	f	f	velocity_cold_start
1373	2024-12-12	Global	1	\N	0.8932120203971863	0	1	f	f	velocity_cold_start
1374	2024-12-12	growth	1	\N	0.8932120203971863	0	1	f	f	velocity_cold_start
1375	2024-12-12	Germany	1	\N	0.8932120203971863	0	1	f	f	velocity_cold_start
1376	2024-12-12	contagion	1	\N	0.8932120203971863	0	1	f	f	velocity_cold_start
1377	2024-12-12	volatility	1	\N	0.8932120203971863	0	1	f	f	velocity_cold_start
1378	2024-12-12	commodities	1	\N	0.8932120203971863	0	1	f	f	velocity_cold_start
1379	2026-01-16	US	1	\N	0	0	1	f	f	velocity_cold_start
1380	2026-01-16	hawkish	2	\N	0	0	1	f	f	velocity_cold_start
1381	2026-01-16	boe_policy	1	\N	0	0	1	f	f	velocity_cold_start
\.


--
-- Data for Name: factor_decomposition_cache; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.factor_decomposition_cache (instrument_id, decomposition, computed_at, expires_at) FROM stdin;
EQ.SPX	{"name": "S&P 500 Index", "factors": [{"id": "f_rates", "r2": 0.0419, "beta": -0.1778, "name": "US 10Y Yield Change", "p_value": 0.0305, "primary_instrument": "RATES.US10Y", "residual_std_error": 0.303855}, {"id": "f_dollar", "r2": 0.0, "beta": -0.1621, "name": "USD Strength", "p_value": 0.2121, "primary_instrument": "FX.DXY", "residual_std_error": 0.303855}, {"id": "f_risk", "r2": 0.6221, "beta": 0.0707, "name": "Risk Sentiment (VIX inv)", "p_value": 0.0, "primary_instrument": "EQ.VIX", "residual_std_error": 0.303855}, {"id": "f_growth", "r2": 0.0, "beta": 0.0197, "name": "Growth (Copper)", "p_value": 0.3167, "primary_instrument": "CM.COPPER", "residual_std_error": 0.303855}, {"id": "f_credit", "r2": 0.0, "beta": -2.1705, "name": "Credit (HY OAS)", "p_value": 0.2266, "primary_instrument": "CREDIT.HY_OAS", "residual_std_error": 0.303855}, {"id": "f_inflation", "r2": 0.0703, "beta": 11.6128, "name": "Inflation (Breakeven)", "p_value": 0.0032, "primary_instrument": "RATES.BREAKEVEN", "residual_std_error": 0.303855}, {"id": "f_market", "r2": 1.0, "beta": 1.0, "name": "Market Beta (EQ.SPX)", "p_value": 0.0, "primary_instrument": "EQ.SPX", "residual_std_error": 0.303855}], "total_r2": 0.8439, "instrument": "EQ.SPX"}	2026-03-19 16:58:00.135055+00	2026-03-20 16:58:00.135055+00
EQ.AAPL	{"name": "Apple Inc.", "factors": [{"id": "f_rates", "r2": 0.0, "beta": 0.4053, "name": "US 10Y Yield Change", "p_value": 0.3619, "primary_instrument": "RATES.US10Y", "residual_std_error": 1.316174}, {"id": "f_dollar", "r2": 0.0, "beta": 0.1579, "name": "USD Strength", "p_value": 0.8017, "primary_instrument": "FX.DXY", "residual_std_error": 1.316174}, {"id": "f_risk", "r2": 0.3337, "beta": 0.1039, "name": "Risk Sentiment (VIX inv)", "p_value": 0.0064, "primary_instrument": "EQ.VIX", "residual_std_error": 1.316174}, {"id": "f_growth", "r2": 0.0, "beta": -0.0618, "name": "Growth (Copper)", "p_value": 0.4392, "primary_instrument": "CM.COPPER", "residual_std_error": 1.316174}, {"id": "f_credit", "r2": 0.0, "beta": 4.1705, "name": "Credit (HY OAS)", "p_value": 0.4386, "primary_instrument": "CREDIT.HY_OAS", "residual_std_error": 1.316174}, {"id": "f_inflation", "r2": 0.0, "beta": -1.5346, "name": "Inflation (Breakeven)", "p_value": 0.924, "primary_instrument": "RATES.BREAKEVEN", "residual_std_error": 1.316174}, {"id": "f_market", "r2": 0.2055, "beta": 0.9094, "name": "Market Beta (EQ.SPX)", "p_value": 0.0015, "primary_instrument": "EQ.SPX", "residual_std_error": 1.316174}], "total_r2": 0.2722, "instrument": "EQ.AAPL"}	2026-03-19 16:58:07.891084+00	2026-03-20 16:58:07.891084+00
EQ.SHEL	{"name": "Shell plc", "factors": [{"id": "f_rates", "r2": 0.0, "beta": 0.1817, "name": "US 10Y Yield Change", "p_value": 0.6087, "primary_instrument": "RATES.US10Y", "residual_std_error": 1.320684}, {"id": "f_dollar", "r2": 0.0, "beta": 0.6933, "name": "USD Strength", "p_value": 0.0998, "primary_instrument": "FX.DXY", "residual_std_error": 1.320684}, {"id": "f_risk", "r2": 0.0, "beta": 0.0458, "name": "Risk Sentiment (VIX inv)", "p_value": 0.1311, "primary_instrument": "EQ.VIX", "residual_std_error": 1.320684}, {"id": "f_growth", "r2": 0.0, "beta": 0.1303, "name": "Growth (Copper)", "p_value": 0.1652, "primary_instrument": "CM.COPPER", "residual_std_error": 1.320684}, {"id": "f_credit", "r2": 0.0, "beta": 9.6212, "name": "Credit (HY OAS)", "p_value": 0.0589, "primary_instrument": "CREDIT.HY_OAS", "residual_std_error": 1.320684}, {"id": "f_inflation", "r2": 0.1301, "beta": 30.8051, "name": "Inflation (Breakeven)", "p_value": 0.0279, "primary_instrument": "RATES.BREAKEVEN", "residual_std_error": 1.320684}, {"id": "f_market", "r2": 0.0, "beta": 0.2068, "name": "Market Beta (EQ.SPX)", "p_value": 0.3567, "primary_instrument": "EQ.SPX", "residual_std_error": 1.320684}], "total_r2": 0.2244, "instrument": "EQ.SHEL"}	2026-03-19 17:05:53.932161+00	2026-03-20 17:05:53.932161+00
EQ.LVMH	{"name": "LVMH Moët Hennessy", "factors": [{"id": "f_rates", "r2": 0.0, "beta": -0.2984, "name": "US 10Y Yield Change", "p_value": 0.374, "primary_instrument": "RATES.US10Y", "residual_std_error": 1.738369}, {"id": "f_dollar", "r2": 0.0, "beta": -0.6235, "name": "USD Strength", "p_value": 0.3516, "primary_instrument": "FX.DXY", "residual_std_error": 1.738369}, {"id": "f_risk", "r2": 0.0, "beta": 0.042, "name": "Risk Sentiment (VIX inv)", "p_value": 0.2624, "primary_instrument": "EQ.VIX", "residual_std_error": 1.738369}, {"id": "f_growth", "r2": 0.0, "beta": -0.0096, "name": "Growth (Copper)", "p_value": 0.9182, "primary_instrument": "CM.COPPER", "residual_std_error": 1.738369}, {"id": "f_credit", "r2": 0.0, "beta": -4.6148, "name": "Credit (HY OAS)", "p_value": 0.4898, "primary_instrument": "CREDIT.HY_OAS", "residual_std_error": 1.738369}, {"id": "f_inflation", "r2": 0.0, "beta": -22.4062, "name": "Inflation (Breakeven)", "p_value": 0.283, "primary_instrument": "RATES.BREAKEVEN", "residual_std_error": 1.738369}, {"id": "f_market", "r2": 0.0474, "beta": 0.5405, "name": "Market Beta (EQ.SPX)", "p_value": 0.0315, "primary_instrument": "EQ.SPX", "residual_std_error": 1.738369}], "total_r2": 0.1697, "instrument": "EQ.LVMH"}	2026-03-19 17:06:37.673303+00	2026-03-20 17:06:37.673303+00
EQ.ASML	{"name": "ASML Holding NV", "factors": [{"id": "f_rates", "r2": 0.0, "beta": -0.5019, "name": "US 10Y Yield Change", "p_value": 0.406, "primary_instrument": "RATES.US10Y", "residual_std_error": 2.29073}, {"id": "f_dollar", "r2": 0.0, "beta": -0.8072, "name": "USD Strength", "p_value": 0.4215, "primary_instrument": "FX.DXY", "residual_std_error": 2.29073}, {"id": "f_risk", "r2": 0.2274, "beta": 0.1674, "name": "Risk Sentiment (VIX inv)", "p_value": 0.008, "primary_instrument": "EQ.VIX", "residual_std_error": 2.29073}, {"id": "f_growth", "r2": 0.0, "beta": 0.1836, "name": "Growth (Copper)", "p_value": 0.2187, "primary_instrument": "CM.COPPER", "residual_std_error": 2.29073}, {"id": "f_credit", "r2": 0.0, "beta": -9.0257, "name": "Credit (HY OAS)", "p_value": 0.3135, "primary_instrument": "CREDIT.HY_OAS", "residual_std_error": 2.29073}, {"id": "f_inflation", "r2": 0.0, "beta": 5.3905, "name": "Inflation (Breakeven)", "p_value": 0.8086, "primary_instrument": "RATES.BREAKEVEN", "residual_std_error": 2.29073}, {"id": "f_market", "r2": 0.4464, "beta": 2.6146, "name": "Market Beta (EQ.SPX)", "p_value": 0.0, "primary_instrument": "EQ.SPX", "residual_std_error": 2.29073}], "total_r2": 0.4207, "instrument": "EQ.ASML"}	2026-03-19 17:43:40.872913+00	2026-03-20 17:43:40.872913+00
\.


--
-- Data for Name: instruments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.instruments (id, name, asset_class, sub_type, geography, sectors, themes, risk_profile, liquidity, yfinance_ticker, fred_series_id, correlates_with, thesis_role, tradeable_via, sector, country, market_cap, currency, index_member, is_active, last_synced) FROM stdin;
EQ.ASML	ASML Holding NV	equity	\N	\N	\N	\N	\N	\N	ASML	\N	\N	\N	\N	Technology	\N	\N	\N	{}	t	\N
EQ.SPX	S&P 500 Index	equity	index	{US}	{}	{risk_on,growth,US}	medium	very_high	^GSPC	\N	{EQ.VIX,FI.US10Y}	{directional,proxy}	{ETF,futures,options}	\N	US	\N	USD	\N	t	\N
EQ.SX7E	Euro Stoxx 50	equity	index	{EU,Eurozone}	{}	{ECB_policy,EU_rates,EU}	medium	very_high	^STOXX50E	\N	{FI.DE10Y,FX.EURUSD}	{directional,proxy}	{ETF,futures,options}	\N	US	\N	USD	\N	t	\N
EQ.VIX	CBOE Volatility Index	equity	index	{US}	{}	{volatility,risk_off,stress}	high	very_high	^VIX	\N	{EQ.SPX,FI.US10Y}	{hedge,directional}	{futures,options}	\N	US	\N	USD	\N	t	\N
EQ.SPY	SPDR S&P 500 ETF	equity	etf	{US}	{}	{risk_on,growth,US}	medium	very_high	SPY	\N	{EQ.SPX}	{directional}	{ETF,options}	\N	US	\N	USD	\N	t	\N
EQ.LQD	iShares Investment Grade Corporate Bond ETF	fixed_income	etf	{US}	{}	{credit_cycle,spreads,IG}	low	very_high	LQD	\N	{EQ.HYG,FI.US10Y}	{directional,proxy}	{ETF}	\N	US	\N	USD	\N	t	\N
EQ.HYG	iShares iBoxx High Yield Corporate Bond ETF	fixed_income	etf	{US}	{}	{credit_cycle,spreads,HY}	high	very_high	HYG	\N	{EQ.LQD,EQ.SPX}	{directional,proxy}	{ETF}	\N	US	\N	USD	\N	t	\N
EQ.IEAC	iShares Euro Corporate Bond ETF	fixed_income	etf	{EU,Eurozone}	{}	{ECB_policy,credit_cycle,EU_rates}	low	high	IEAC.L	\N	{FI.DE10Y,FI.IT10Y}	{directional,proxy}	{ETF}	\N	US	\N	USD	\N	t	\N
FI.US2Y	US 2-Year Treasury Yield	rates	sovereign	{US}	{}	{fed_policy,US_rates}	low	very_high	\N	DGS2	{FI.US10Y,FI.US10Y2Y}	{directional,pair_leg}	{futures,cash_bond}	\N	US	\N	USD	\N	t	\N
FI.US5Y	US 5-Year Treasury Yield	rates	sovereign	{US}	{}	{fed_policy,US_rates}	low	very_high	\N	DGS5	{FI.US2Y,FI.US10Y}	{directional}	{futures,cash_bond}	\N	US	\N	USD	\N	t	\N
FI.US10Y	US 10-Year Treasury Yield	rates	sovereign	{US}	{}	{fed_policy,US_rates,growth}	low	very_high	\N	DGS10	{FI.US2Y,FI.US10Y2Y,EQ.SPX}	{directional,pair_leg}	{futures,cash_bond}	\N	US	\N	USD	\N	t	\N
FI.BAMLHY	ICE BofA US High Yield Option-Adjusted Spread	fixed_income	corp_ig	{US}	{}	{credit_cycle,spreads,HY}	high	high	\N	BAMLH0A0HYM2	{EQ.HYG,EQ.SPX}	{directional}	{ETF}	\N	US	\N	USD	\N	t	\N
CM.WTI	WTI Crude Oil	commodity	future	{US}	{energy}	{energy,commodities}	high	very_high	CL=F	\N	{CM.BRENT}	{directional}	{futures,options}	\N	US	\N	USD	\N	t	\N
CM.BRENT	Brent Crude Oil	commodity	future	{Global}	{energy}	{energy,commodities}	high	very_high	BZ=F	\N	{CM.WTI}	{directional}	{futures,options}	\N	US	\N	USD	\N	t	\N
CM.GOLD	Gold	commodity	future	{Global}	{}	{real_yield,risk_off}	medium	very_high	GC=F	\N	{FI.US10YTIPS,EQ.VIX}	{directional,hedge}	{futures,options,ETF}	\N	US	\N	USD	\N	t	\N
CM.COPPER	Copper	commodity	future	{Global}	{commodities}	{growth,infrastructure}	high	very_high	HG=F	\N	{CM.GOLD,EQ.SPX}	{directional}	{futures}	\N	US	\N	USD	\N	t	\N
CM.NATGAS	Natural Gas	commodity	future	{US}	{energy}	{energy}	very_high	high	NG=F	\N	{CM.WTI}	{directional}	{futures}	\N	US	\N	USD	\N	t	\N
FX.EURUSD	EUR/USD	fx	index	{EU,US}	{}	{ECB_policy,fed_policy}	medium	very_high	EURUSD=X	\N	{FI.DE10Y,FI.US10Y}	{directional}	{futures,options}	\N	US	\N	USD	\N	t	\N
FX.GBPUSD	GBP/USD	fx	index	{UK,US}	{}	{boe_policy,fed_policy}	medium	very_high	GBPUSD=X	\N	{FI.UK10Y}	{directional}	{futures,options}	\N	US	\N	USD	\N	t	\N
FX.USDJPY	USD/JPY	fx	index	{Japan,US}	{}	{risk_on,Japan}	medium	very_high	USDJPY=X	\N	{FI.US10Y}	{directional}	{futures,options}	\N	US	\N	USD	\N	t	\N
FX.DXY	US Dollar Index	fx	index	{US}	{}	{dollar_strength}	medium	very_high	DX-Y.NYB	\N	{FX.EURUSD,CM.GOLD}	{directional}	{futures}	\N	US	\N	USD	\N	t	\N
EQ.XLE	Energy Select Sector SPDR	equity	etf	{US}	{energy}	{energy,US}	high	very_high	XLE	\N	{CM.WTI,CM.BRENT}	{directional}	{ETF,options}	\N	US	\N	USD	\N	t	\N
EQ.XLF	Financial Select Sector SPDR	equity	etf	{US}	{banking}	{rates_sensitive,US}	medium	very_high	XLF	\N	{FI.US10Y,EQ.SPX}	{directional}	{ETF,options}	\N	US	\N	USD	\N	t	\N
EQ.XLU	Utilities Select Sector SPDR	equity	etf	{US}	{infrastructure}	{rates_sensitive}	low	very_high	XLU	\N	{FI.US10Y}	{directional}	{ETF}	\N	US	\N	USD	\N	t	\N
EQ.EEM	iShares MSCI Emerging Markets ETF	equity	etf	{EM}	{}	{risk_on,EM}	high	very_high	EEM	\N	{EQ.SPX,FX.DXY}	{directional}	{ETF}	\N	US	\N	USD	\N	t	\N
EQ.GLD	SPDR Gold Shares	commodity	etf	{Global}	{}	{real_yield,risk_off}	medium	very_high	GLD	\N	{CM.GOLD}	{directional,hedge}	{ETF}	\N	US	\N	USD	\N	t	\N
EQ.SLV	iShares Silver Trust	commodity	etf	{Global}	{}	{commodities}	high	very_high	SLV	\N	{CM.GOLD}	{directional}	{ETF}	\N	US	\N	USD	\N	t	\N
EQ.XLK	Technology Select Sector SPDR	equity	etf	{US}	{technology}	{risk_on,growth,US}	high	very_high	XLK	\N	{EQ.SPX}	{directional}	{ETF,options}	\N	US	\N	USD	\N	t	\N
EQ.XLV	Health Care Select Sector SPDR	equity	etf	{US}	{}	{rates_sensitive,US}	medium	very_high	XLV	\N	{EQ.SPX}	{directional}	{ETF,options}	\N	US	\N	USD	\N	t	\N
EQ.XLY	Consumer Discretionary Select Sector SPDR	equity	etf	{US}	{}	{growth,US}	high	very_high	XLY	\N	{EQ.SPX}	{directional}	{ETF,options}	\N	US	\N	USD	\N	t	\N
EQ.XLP	Consumer Staples Select Sector SPDR	equity	etf	{US}	{}	{US}	low	very_high	XLP	\N	{EQ.SPX}	{directional}	{ETF}	\N	US	\N	USD	\N	t	\N
EQ.XLI	Industrial Select Sector SPDR	equity	etf	{US}	{infrastructure}	{growth,US}	medium	very_high	XLI	\N	{EQ.SPX,CM.COPPER}	{directional}	{ETF,options}	\N	US	\N	USD	\N	t	\N
EQ.XLB	Materials Select Sector SPDR	equity	etf	{US}	{commodities}	{commodities,US}	high	very_high	XLB	\N	{CM.COPPER,CM.GOLD}	{directional}	{ETF,options}	\N	US	\N	USD	\N	t	\N
FX.AUDUSD	AUD/USD	fx	index	{Australia,US}	{}	{risk_on}	medium	very_high	AUDUSD=X	\N	{CM.GOLD,FX.DXY}	{directional}	{futures,options}	\N	US	\N	USD	\N	t	\N
FX.EURGBP	EUR/GBP	fx	index	{EU,UK}	{}	{ECB_policy,boe_policy}	medium	very_high	EURGBP=X	\N	{FX.EURUSD,FX.GBPUSD}	{directional}	{futures,options}	\N	US	\N	USD	\N	t	\N
FI.ES10Y	Spain 10-Year Government Bond Yield	rates	sovereign	{Spain,EU}	{}	{ECB_policy,EU_rates}	medium	very_high	\N	\N	{FI.IT10Y,FI.DE10Y}	{directional}	{futures,cash_bond}	\N	US	\N	USD	\N	t	\N
MACRO.INDPRO	US Industrial Production Index	macro	index	{US}	{}	{growth}	low	high	\N	INDPRO	{}	{directional}	{}	\N	US	\N	USD	\N	t	\N
MACRO.RETAIL	US Advance Retail Sales	macro	index	{US}	{}	{growth}	low	high	\N	RSAFS	{}	{directional}	{}	\N	US	\N	USD	\N	t	\N
MACRO.UMCSENT	U of Michigan Consumer Sentiment	macro	index	{US}	{}	{growth}	low	high	\N	UMCSENT	{}	{directional}	{}	\N	US	\N	USD	\N	t	\N
FI.US30Y	US 30-Year Treasury Yield	rates	sovereign	{US}	{}	{fed_policy,US_rates}	low	very_high	\N	DGS30	{FI.US10Y}	{directional}	{futures,cash_bond}	\N	US	\N	USD	\N	t	\N
FI.US10Y2Y	US 2s10s Yield Curve	rates	sovereign	{US}	{}	{fed_policy,recession,curve_shape}	low	very_high	\N	T10Y2Y	{FI.US2Y,FI.US10Y}	{directional}	{futures}	\N	US	\N	USD	\N	t	\N
FI.US10YIE	US 10-Year Breakeven Inflation	rates	sovereign	{US}	{}	{inflation,breakeven_inflation}	low	high	\N	T10YIE	{FI.US10Y}	{directional}	{futures}	\N	US	\N	USD	\N	t	\N
RATES.US10Y	US 10-Year Treasury Yield	rates	sovereign	{US}	{}	{fed_policy,US_rates,growth}	low	very_high	\N	DGS10	{}	{directional,pair_leg}	{futures,cash_bond}	\N	US	\N	USD	\N	t	\N
RATES.US30Y	US 30-Year Treasury Yield	rates	sovereign	{US}	{}	{fed_policy,US_rates}	low	very_high	\N	DGS30	{}	{directional}	{futures,cash_bond}	\N	US	\N	USD	\N	t	\N
RATES.2S10S	US 2s10s Yield Curve Spread	rates	sovereign	{US}	{}	{fed_policy,recession,curve_shape}	low	very_high	\N	T10Y2Y	{}	{directional}	{futures}	\N	US	\N	USD	\N	t	\N
MACRO.ISM_MFG	US Manufacturing Employment (proxy)	macro	index	{US}	{}	{growth,labour_market}	low	high	\N	MANEMP	{}	{directional}	{}	\N	US	\N	USD	\N	t	\N
FX.USDCHF	USD/CHF	fx	index	{Switzerland,US}	{}	{risk_off}	medium	very_high	USDCHF=X	\N	{}	{directional}	{futures,options}	\N	US	\N	USD	\N	t	\N
CM.WHEAT	Wheat Futures	commodity	future	{Global}	{}	{commodities}	high	high	ZW=F	\N	{}	{directional}	{futures}	\N	US	\N	USD	\N	t	\N
EQ.AAPL	Apple Inc.	equity	\N	\N	\N	\N	\N	\N	AAPL	\N	\N	\N	\N	Technology	US	large	USD	{SP500}	t	\N
EQ.MSFT	Microsoft Corp.	equity	\N	\N	\N	\N	\N	\N	MSFT	\N	\N	\N	\N	Technology	US	large	USD	{SP500}	t	\N
EQ.NVDA	Nvidia Corp.	equity	\N	\N	\N	\N	\N	\N	NVDA	\N	\N	\N	\N	Technology	US	large	USD	{SP500}	t	\N
EQ.META	Meta Platforms	equity	\N	\N	\N	\N	\N	\N	META	\N	\N	\N	\N	Technology	US	large	USD	{SP500}	t	\N
EQ.GOOGL	Alphabet Inc.	equity	\N	\N	\N	\N	\N	\N	GOOGL	\N	\N	\N	\N	Technology	US	large	USD	{SP500}	t	\N
EQ.AMZN	Amazon.com Inc.	equity	\N	\N	\N	\N	\N	\N	AMZN	\N	\N	\N	\N	Consumer Cyclical	US	large	USD	{SP500}	t	\N
EQ.TSLA	Tesla Inc.	equity	\N	\N	\N	\N	\N	\N	TSLA	\N	\N	\N	\N	Consumer Cyclical	US	large	USD	{SP500}	t	\N
EQ.AVGO	Broadcom Inc.	equity	\N	\N	\N	\N	\N	\N	AVGO	\N	\N	\N	\N	Technology	US	large	USD	{SP500}	t	\N
EQ.CRM	Salesforce Inc.	equity	\N	\N	\N	\N	\N	\N	CRM	\N	\N	\N	\N	Technology	US	large	USD	{SP500}	t	\N
EQ.AMD	Advanced Micro Devices	equity	\N	\N	\N	\N	\N	\N	AMD	\N	\N	\N	\N	Technology	US	large	USD	{SP500}	t	\N
EQ.JPM	JPMorgan Chase	equity	\N	\N	\N	\N	\N	\N	JPM	\N	\N	\N	\N	Financials	US	large	USD	{SP500}	t	\N
EQ.BAC	Bank of America	equity	\N	\N	\N	\N	\N	\N	BAC	\N	\N	\N	\N	Financials	US	large	USD	{SP500}	t	\N
EQ.GS	Goldman Sachs	equity	\N	\N	\N	\N	\N	\N	GS	\N	\N	\N	\N	Financials	US	large	USD	{SP500}	t	\N
EQ.MS	Morgan Stanley	equity	\N	\N	\N	\N	\N	\N	MS	\N	\N	\N	\N	Financials	US	large	USD	{SP500}	t	\N
EQ.BLK	BlackRock Inc.	equity	\N	\N	\N	\N	\N	\N	BLK	\N	\N	\N	\N	Financials	US	large	USD	{SP500}	t	\N
EQ.BRK_B	Berkshire Hathaway B	equity	\N	\N	\N	\N	\N	\N	BRK-B	\N	\N	\N	\N	Financials	US	large	USD	{SP500}	t	\N
EQ.C	Citigroup Inc.	equity	\N	\N	\N	\N	\N	\N	C	\N	\N	\N	\N	Financials	US	large	USD	{SP500}	t	\N
EQ.WFC	Wells Fargo	equity	\N	\N	\N	\N	\N	\N	WFC	\N	\N	\N	\N	Financials	US	large	USD	{SP500}	t	\N
EQ.LLY	Eli Lilly	equity	\N	\N	\N	\N	\N	\N	LLY	\N	\N	\N	\N	Healthcare	US	large	USD	{SP500}	t	\N
EQ.UNH	UnitedHealth Group	equity	\N	\N	\N	\N	\N	\N	UNH	\N	\N	\N	\N	Healthcare	US	large	USD	{SP500}	t	\N
EQ.JNJ	Johnson & Johnson	equity	\N	\N	\N	\N	\N	\N	JNJ	\N	\N	\N	\N	Healthcare	US	large	USD	{SP500}	t	\N
EQ.ABBV	AbbVie Inc.	equity	\N	\N	\N	\N	\N	\N	ABBV	\N	\N	\N	\N	Healthcare	US	large	USD	{SP500}	t	\N
EQ.MRK	Merck & Co.	equity	\N	\N	\N	\N	\N	\N	MRK	\N	\N	\N	\N	Healthcare	US	large	USD	{SP500}	t	\N
EQ.PFE	Pfizer Inc.	equity	\N	\N	\N	\N	\N	\N	PFE	\N	\N	\N	\N	Healthcare	US	large	USD	{SP500}	t	\N
EQ.XOM	Exxon Mobil	equity	\N	\N	\N	\N	\N	\N	XOM	\N	\N	\N	\N	Energy	US	large	USD	{SP500}	t	\N
EQ.CVX	Chevron Corp.	equity	\N	\N	\N	\N	\N	\N	CVX	\N	\N	\N	\N	Energy	US	large	USD	{SP500}	t	\N
FI.US10YTIPS	US 10-Year TIPS Yield (Real Yield)	rates	sovereign	{US}	{}	{real_yield,inflation}	low	high	\N	DFII10	{FI.US10Y,CM.GOLD}	{directional}	{futures,cash_bond}	\N	US	\N	USD	\N	t	\N
FI.DE2Y	Germany 2-Year Yield	rates	sovereign	{Germany,EU}	{}	{ECB_policy,EU_rates}	low	very_high	\N	\N	{FI.DE10Y}	{directional}	{futures,cash_bond}	\N	US	\N	USD	\N	t	\N
FI.DE10Y	Germany 10-Year Yield (Bund)	rates	sovereign	{Germany,EU}	{}	{ECB_policy,EU_rates}	low	very_high	\N	IRLTCT01DEM156N	{FI.IT10Y,FI.FR10Y,FX.EURUSD}	{directional,pair_leg}	{futures,cash_bond}	\N	US	\N	USD	\N	t	\N
FI.IT10Y	Italy 10-Year Yield (BTP)	rates	sovereign	{Italy,EU}	{}	{ECB_policy,EU_rates,credit_cycle}	medium	very_high	\N	IRLTCT01ITM156N	{FI.DE10Y}	{directional,pair_leg}	{futures,cash_bond}	\N	US	\N	USD	\N	t	\N
FI.FR10Y	France 10-Year Yield (OAT)	rates	sovereign	{France,EU}	{}	{ECB_policy,EU_rates}	low	very_high	\N	\N	{FI.DE10Y,FI.IT10Y}	{directional}	{futures,cash_bond}	\N	US	\N	USD	\N	t	\N
FI.UK10Y	UK 10-Year Gilt Yield	rates	sovereign	{UK}	{}	{boe_policy,UK}	low	very_high	\N	IRLTCT01GBM156N	{FI.US10Y,FX.GBPUSD}	{directional}	{futures,cash_bond}	\N	US	\N	USD	\N	t	\N
EQ.IWM	iShares Russell 2000 ETF	equity	etf	{US}	{}	{risk_on,growth,US}	high	very_high	IWM	\N	{EQ.SPX}	{directional}	{ETF,options}	\N	US	\N	USD	\N	t	\N
CM.IRON_ORE	Iron Ore Futures	commodity	future	{Global}	{}	{commodities,growth}	high	high	TIO=F	\N	{}	{directional}	{futures}	\N	US	\N	USD	\N	t	\N
EQ.STOXX600	STOXX Europe 600	equity	index	{EU}	{}	{EU,risk_on}	medium	very_high	^STOXX	\N	{}	{directional}	{ETF,futures}	\N	US	\N	USD	\N	t	\N
EQ.DAX	DAX	equity	index	{Germany,EU}	{}	{EU,ECB_policy}	medium	very_high	^GDAXI	\N	{}	{directional}	{ETF,futures}	\N	US	\N	USD	\N	t	\N
EQ.COP	ConocoPhillips	equity	\N	\N	\N	\N	\N	\N	COP	\N	\N	\N	\N	Energy	US	large	USD	{SP500}	t	\N
EQ.SLB	SLB (Schlumberger)	equity	\N	\N	\N	\N	\N	\N	SLB	\N	\N	\N	\N	Energy	US	large	USD	{SP500}	t	\N
EQ.WMT	Walmart Inc.	equity	\N	\N	\N	\N	\N	\N	WMT	\N	\N	\N	\N	Consumer Defensive	US	large	USD	{SP500}	t	\N
EQ.COST	Costco Wholesale	equity	\N	\N	\N	\N	\N	\N	COST	\N	\N	\N	\N	Consumer Defensive	US	large	USD	{SP500}	t	\N
EQ.PG	Procter & Gamble	equity	\N	\N	\N	\N	\N	\N	PG	\N	\N	\N	\N	Consumer Defensive	US	large	USD	{SP500}	t	\N
EQ.KO	Coca-Cola Co.	equity	\N	\N	\N	\N	\N	\N	KO	\N	\N	\N	\N	Consumer Defensive	US	large	USD	{SP500}	t	\N
EQ.MCD	McDonald's Corp.	equity	\N	\N	\N	\N	\N	\N	MCD	\N	\N	\N	\N	Consumer Cyclical	US	large	USD	{SP500}	t	\N
EQ.NKE	Nike Inc.	equity	\N	\N	\N	\N	\N	\N	NKE	\N	\N	\N	\N	Consumer Cyclical	US	large	USD	{SP500}	t	\N
EQ.CAT	Caterpillar Inc.	equity	\N	\N	\N	\N	\N	\N	CAT	\N	\N	\N	\N	Industrials	US	large	USD	{SP500}	t	\N
EQ.BA	Boeing Co.	equity	\N	\N	\N	\N	\N	\N	BA	\N	\N	\N	\N	Industrials	US	large	USD	{SP500}	t	\N
EQ.RTX	RTX Corp. (Raytheon)	equity	\N	\N	\N	\N	\N	\N	RTX	\N	\N	\N	\N	Industrials	US	large	USD	{SP500}	t	\N
EQ.HON	Honeywell International	equity	\N	\N	\N	\N	\N	\N	HON	\N	\N	\N	\N	Industrials	US	large	USD	{SP500}	t	\N
EQ.NEE	NextEra Energy	equity	\N	\N	\N	\N	\N	\N	NEE	\N	\N	\N	\N	Utilities	US	large	USD	{SP500}	t	\N
EQ.AMT	American Tower	equity	\N	\N	\N	\N	\N	\N	AMT	\N	\N	\N	\N	Real Estate	US	large	USD	{SP500}	t	\N
EQ.SHEL	Shell plc	equity	\N	\N	\N	\N	\N	\N	SHEL.L	\N	\N	\N	\N	Energy	GB	large	GBP	{FTSE100}	t	\N
EQ.AZN	AstraZeneca plc	equity	\N	\N	\N	\N	\N	\N	AZN.L	\N	\N	\N	\N	Healthcare	GB	large	GBP	{FTSE100}	t	\N
EQ.HSBA	HSBC Holdings	equity	\N	\N	\N	\N	\N	\N	HSBA.L	\N	\N	\N	\N	Financials	GB	large	GBP	{FTSE100}	t	\N
EQ.ULVR	Unilever plc	equity	\N	\N	\N	\N	\N	\N	ULVR.L	\N	\N	\N	\N	Consumer	GB	large	GBP	{FTSE100}	t	\N
EQ.DGE	Diageo plc	equity	\N	\N	\N	\N	\N	\N	DGE.L	\N	\N	\N	\N	Consumer	GB	large	GBP	{FTSE100}	t	\N
EQ.RIO	Rio Tinto plc	equity	\N	\N	\N	\N	\N	\N	RIO.L	\N	\N	\N	\N	Materials	GB	large	GBP	{FTSE100}	t	\N
EQ.BP	BP plc	equity	\N	\N	\N	\N	\N	\N	BP.L	\N	\N	\N	\N	Energy	GB	large	GBP	{FTSE100}	t	\N
EQ.LLOY	Lloyds Banking Group	equity	\N	\N	\N	\N	\N	\N	LLOY.L	\N	\N	\N	\N	Financials	GB	large	GBP	{FTSE100}	t	\N
EQ.BARC	Barclays plc	equity	\N	\N	\N	\N	\N	\N	BARC.L	\N	\N	\N	\N	Financials	GB	large	GBP	{FTSE100}	t	\N
EQ.GSK	GSK plc	equity	\N	\N	\N	\N	\N	\N	GSK.L	\N	\N	\N	\N	Healthcare	GB	large	GBP	{FTSE100}	t	\N
EQ.VOD	Vodafone Group	equity	\N	\N	\N	\N	\N	\N	VOD.L	\N	\N	\N	\N	Telecom	GB	large	GBP	{FTSE100}	t	\N
EQ.NWG	NatWest Group	equity	\N	\N	\N	\N	\N	\N	NWG.L	\N	\N	\N	\N	Financials	GB	large	GBP	{FTSE100}	t	\N
EQ.SAP	SAP SE	equity	\N	\N	\N	\N	\N	\N	SAP.DE	\N	\N	\N	\N	Technology	DE	large	EUR	{DAX}	t	\N
EQ.SIE	Siemens AG	equity	\N	\N	\N	\N	\N	\N	SIE.DE	\N	\N	\N	\N	Industrials	DE	large	EUR	{DAX}	t	\N
EQ.ALV	Allianz SE	equity	\N	\N	\N	\N	\N	\N	ALV.DE	\N	\N	\N	\N	Financials	DE	large	EUR	{DAX}	t	\N
EQ.DTE	Deutsche Telekom	equity	\N	\N	\N	\N	\N	\N	DTE.DE	\N	\N	\N	\N	Telecom	DE	large	EUR	{DAX}	t	\N
EQ.MUV2	Munich Re	equity	\N	\N	\N	\N	\N	\N	MUV2.DE	\N	\N	\N	\N	Financials	DE	large	EUR	{DAX}	t	\N
EQ.BAYN	Bayer AG	equity	\N	\N	\N	\N	\N	\N	BAYN.DE	\N	\N	\N	\N	Healthcare	DE	large	EUR	{DAX}	t	\N
EQ.BMW	BMW AG	equity	\N	\N	\N	\N	\N	\N	BMW.DE	\N	\N	\N	\N	Consumer	DE	large	EUR	{DAX}	t	\N
EQ.VOW3	Volkswagen AG	equity	\N	\N	\N	\N	\N	\N	VOW3.DE	\N	\N	\N	\N	Consumer	DE	large	EUR	{DAX}	t	\N
EQ.ADS	Adidas AG	equity	\N	\N	\N	\N	\N	\N	ADS.DE	\N	\N	\N	\N	Consumer	DE	large	EUR	{DAX}	t	\N
EQ.DBK	Deutsche Bank	equity	\N	\N	\N	\N	\N	\N	DBK.DE	\N	\N	\N	\N	Financials	DE	large	EUR	{DAX}	t	\N
EQ.RHM	Rheinmetall AG	equity	\N	\N	\N	\N	\N	\N	RHM.DE	\N	\N	\N	\N	Industrials	DE	large	EUR	{DAX}	t	\N
EQ.LVMH	LVMH Moët Hennessy	equity	\N	\N	\N	\N	\N	\N	MC.PA	\N	\N	\N	\N	Consumer	FR	large	EUR	{CAC40}	t	\N
EQ.TTE	TotalEnergies SE	equity	\N	\N	\N	\N	\N	\N	TTE.PA	\N	\N	\N	\N	Energy	FR	large	EUR	{CAC40}	t	\N
EQ.SAN	Sanofi SA	equity	\N	\N	\N	\N	\N	\N	SAN.PA	\N	\N	\N	\N	Healthcare	FR	large	EUR	{CAC40}	t	\N
EQ.BNP	BNP Paribas	equity	\N	\N	\N	\N	\N	\N	BNP.PA	\N	\N	\N	\N	Financials	FR	large	EUR	{CAC40}	t	\N
EQ.AIR	Airbus SE	equity	\N	\N	\N	\N	\N	\N	AIR.PA	\N	\N	\N	\N	Industrials	FR	large	EUR	{CAC40}	t	\N
EQ.OR	L'Oréal SA	equity	\N	\N	\N	\N	\N	\N	OR.PA	\N	\N	\N	\N	Consumer	FR	large	EUR	{CAC40}	t	\N
EQ.SG	Société Générale	equity	\N	\N	\N	\N	\N	\N	GLE.PA	\N	\N	\N	\N	Financials	FR	large	EUR	{CAC40}	t	\N
EQ.AXA	AXA SA	equity	\N	\N	\N	\N	\N	\N	CS.PA	\N	\N	\N	\N	Financials	FR	large	EUR	{CAC40}	t	\N
EQ.HO	Thales SA	equity	\N	\N	\N	\N	\N	\N	HO.PA	\N	\N	\N	\N	Industrials	FR	large	EUR	{CAC40}	t	\N
EQ.ENGI	Engie SA	equity	\N	\N	\N	\N	\N	\N	ENGI.PA	\N	\N	\N	\N	Utilities	FR	large	EUR	{CAC40}	t	\N
ETF.XLE	Energy Select Sector SPDR	etf	\N	\N	\N	\N	\N	\N	XLE	\N	\N	\N	\N	Energy	US	\N	USD	\N	t	\N
ETF.XLF	Financials Select Sector SPDR	etf	\N	\N	\N	\N	\N	\N	XLF	\N	\N	\N	\N	Financials	US	\N	USD	\N	t	\N
ETF.XLK	Technology Select Sector SPDR	etf	\N	\N	\N	\N	\N	\N	XLK	\N	\N	\N	\N	Technology	US	\N	USD	\N	t	\N
ETF.XLV	Healthcare Select Sector SPDR	etf	\N	\N	\N	\N	\N	\N	XLV	\N	\N	\N	\N	Healthcare	US	\N	USD	\N	t	\N
ETF.XLI	Industrials Select Sector SPDR	etf	\N	\N	\N	\N	\N	\N	XLI	\N	\N	\N	\N	Industrials	US	\N	USD	\N	t	\N
ETF.XLB	Materials Select Sector SPDR	etf	\N	\N	\N	\N	\N	\N	XLB	\N	\N	\N	\N	Materials	US	\N	USD	\N	t	\N
ETF.XLY	Consumer Discretionary SPDR	etf	\N	\N	\N	\N	\N	\N	XLY	\N	\N	\N	\N	Consumer	US	\N	USD	\N	t	\N
ETF.XLP	Consumer Staples SPDR	etf	\N	\N	\N	\N	\N	\N	XLP	\N	\N	\N	\N	Consumer	US	\N	USD	\N	t	\N
ETF.XLU	Utilities Select Sector SPDR	etf	\N	\N	\N	\N	\N	\N	XLU	\N	\N	\N	\N	Utilities	US	\N	USD	\N	t	\N
ETF.XLRE	Real Estate Select Sector SPDR	etf	\N	\N	\N	\N	\N	\N	XLRE	\N	\N	\N	\N	Real Estate	US	\N	USD	\N	t	\N
ETF.SPY	SPDR S&P 500 ETF	etf	\N	\N	\N	\N	\N	\N	SPY	\N	\N	\N	\N	Broad Market	US	\N	USD	\N	t	\N
ETF.QQQ	Invesco QQQ (Nasdaq 100)	etf	\N	\N	\N	\N	\N	\N	QQQ	\N	\N	\N	\N	Broad Market	US	\N	USD	\N	t	\N
ETF.IWM	iShares Russell 2000 ETF	etf	\N	\N	\N	\N	\N	\N	IWM	\N	\N	\N	\N	Broad Market	US	\N	USD	\N	t	\N
ETF.DIA	SPDR Dow Jones Industrial Avg	etf	\N	\N	\N	\N	\N	\N	DIA	\N	\N	\N	\N	Broad Market	US	\N	USD	\N	t	\N
ETF.EZU	iShares MSCI Eurozone ETF	etf	\N	\N	\N	\N	\N	\N	EZU	\N	\N	\N	\N	Broad Market	US	\N	USD	\N	t	\N
ETF.EWU	iShares MSCI United Kingdom ETF	etf	\N	\N	\N	\N	\N	\N	EWU	\N	\N	\N	\N	Broad Market	US	\N	USD	\N	t	\N
ETF.EWG	iShares MSCI Germany ETF	etf	\N	\N	\N	\N	\N	\N	EWG	\N	\N	\N	\N	Broad Market	US	\N	USD	\N	t	\N
ETF.EWQ	iShares MSCI France ETF	etf	\N	\N	\N	\N	\N	\N	EWQ	\N	\N	\N	\N	Broad Market	US	\N	USD	\N	t	\N
ETF.LQD	iShares IG Corporate Bond ETF	etf	\N	\N	\N	\N	\N	\N	LQD	\N	\N	\N	\N	Fixed Income	US	\N	USD	\N	t	\N
ETF.HYG	iShares HY Corporate Bond ETF	etf	\N	\N	\N	\N	\N	\N	HYG	\N	\N	\N	\N	Fixed Income	US	\N	USD	\N	t	\N
ETF.TLT	iShares 20+ Year Treasury ETF	etf	\N	\N	\N	\N	\N	\N	TLT	\N	\N	\N	\N	Fixed Income	US	\N	USD	\N	t	\N
ETF.SHY	iShares 1-3 Year Treasury ETF	etf	\N	\N	\N	\N	\N	\N	SHY	\N	\N	\N	\N	Fixed Income	US	\N	USD	\N	t	\N
ETF.GLD	SPDR Gold Shares	etf	\N	\N	\N	\N	\N	\N	GLD	\N	\N	\N	\N	Commodities	US	\N	USD	\N	t	\N
ETF.USO	United States Oil Fund	etf	\N	\N	\N	\N	\N	\N	USO	\N	\N	\N	\N	Commodities	US	\N	USD	\N	t	\N
EQ.IHYG	iShares Euro High Yield Corporate Bond ETF	fixed_income	etf	{EU,Eurozone}	{}	{credit_cycle,spreads,HY,ECB_policy}	high	high	IHYG.L	\N	{EQ.IEAC,FI.IT10Y}	{directional,proxy}	{ETF}	\N	US	\N	USD	\N	t	\N
CM.SILVER	Silver	commodity	future	{Global}	{}	{commodities}	high	very_high	SI=F	\N	{CM.GOLD}	{directional}	{futures}	\N	US	\N	USD	\N	t	\N
FI.US3M	US 3-Month Treasury Yield	rates	sovereign	{US}	{}	{fed_policy,US_rates}	low	very_high	\N	DGS3MO	{FI.US2Y}	{directional}	{futures}	\N	US	\N	USD	\N	t	\N
FI.TED	TED Spread	rates	sovereign	{US}	{}	{credit_stress,liquidity}	low	high	\N	TEDRATE	{EQ.VIX}	{directional}	{}	\N	US	\N	USD	\N	t	\N
EQ.MOVE	ICE BofA MOVE Index (Bond Volatility)	rates	index	{US}	{}	{volatility,rates_volatility}	high	high	^MOVE	\N	{EQ.VIX,FI.US10Y}	{hedge,directional}	{futures}	\N	US	\N	USD	\N	t	\N
RATES.US3M	US 3-Month Treasury Yield	rates	sovereign	{US}	{}	{fed_policy,US_rates}	low	very_high	\N	DGS3MO	{}	{directional}	{futures}	\N	US	\N	USD	\N	t	\N
EQ.FTSE	FTSE 100	equity	index	{UK}	{}	{boe_policy,UK}	medium	very_high	^FTSE	\N	{}	{directional}	{ETF,futures}	\N	US	\N	USD	\N	t	\N
EQ.NIKKEI	Nikkei 225	equity	index	{Japan}	{}	{Japan}	medium	very_high	^N225	\N	{}	{directional}	{ETF,futures}	\N	US	\N	USD	\N	t	\N
CREDIT.IG_HY_DIFF	HY-IG OAS Spread (computed)	fixed_income	index	{US}	{}	{credit_cycle,spreads}	medium	high	\N	\N	{}	{directional}	{}	\N	US	\N	USD	\N	t	\N
CM.COPPER_GOLD_RATIO	Copper/Gold Ratio (growth pulse)	commodity	index	{Global}	{}	{growth,commodities}	medium	high	\N	\N	{}	{directional}	{}	\N	US	\N	USD	\N	t	\N
RATES.REAL_TERM_PREM	10Y Real Term Premium (rough)	rates	sovereign	{US}	{}	{real_yield,inflation}	low	high	\N	\N	{}	{directional}	{}	\N	US	\N	USD	\N	t	\N
EQ.TSMC	Taiwan Semiconductor	equity	\N	\N	\N	\N	\N	\N	TSMC	\N	\N	\N	\N	Technology	\N	\N	\N	{}	t	\N
RATES.US2Y	US 2-Year Treasury Yield	rates	sovereign	{US}	{}	{fed_policy,US_rates}	low	very_high	\N	DGS2	{}	{directional,pair_leg}	{futures,cash_bond}	\N	US	\N	USD	\N	t	\N
RATES.US5Y	US 5-Year Treasury Yield	rates	sovereign	{US}	{}	{fed_policy,US_rates}	low	very_high	\N	DGS5	{}	{directional}	{futures,cash_bond}	\N	US	\N	USD	\N	t	\N
RATES.5S30S	US 5s30s Yield Curve Spread (computed)	rates	sovereign	{US}	{}	{fed_policy,curve_shape}	low	high	\N	\N	{}	{directional}	{}	\N	US	\N	USD	\N	t	\N
RATES.REAL10Y	US 10-Year TIPS Yield (Real Yield)	rates	sovereign	{US}	{}	{real_yield,inflation}	low	high	\N	DFII10	{}	{directional}	{futures,cash_bond}	\N	US	\N	USD	\N	t	\N
RATES.REAL5Y	US 5-Year TIPS Yield (Real Yield)	rates	sovereign	{US}	{}	{real_yield,inflation}	low	high	\N	DFII5	{}	{directional}	{futures}	\N	US	\N	USD	\N	t	\N
RATES.BREAKEVEN	US 10-Year Breakeven Inflation	rates	sovereign	{US}	{}	{inflation,breakeven_inflation}	low	high	\N	T10YIE	{}	{directional}	{futures}	\N	US	\N	USD	\N	t	\N
RATES.BREAKEVEN5Y	US 5-Year Breakeven Inflation	rates	sovereign	{US}	{}	{inflation,breakeven_inflation}	low	high	\N	T5YIE	{}	{directional}	{futures}	\N	US	\N	USD	\N	t	\N
CREDIT.IG_OAS	ICE BofA US IG Corporate OAS	fixed_income	index	{US}	{}	{credit_cycle,spreads,IG}	medium	high	\N	BAMLC0A0CM	{}	{directional,proxy}	{}	\N	US	\N	USD	\N	t	\N
CREDIT.HY_OAS	ICE BofA US HY Corporate OAS	fixed_income	index	{US}	{}	{credit_cycle,spreads,HY}	high	high	\N	BAMLH0A0HYM2	{}	{directional,proxy}	{}	\N	US	\N	USD	\N	t	\N
MACRO.CPI	US CPI All Urban Consumers	macro	index	{US}	{}	{inflation}	low	high	\N	CPIAUCSL	{}	{directional}	{}	\N	US	\N	USD	\N	t	\N
MACRO.UNRATE	US Unemployment Rate	macro	index	{US}	{}	{labour_market}	low	high	\N	UNRATE	{}	{directional}	{}	\N	US	\N	USD	\N	t	\N
EQ.FAKE999	Fake Instrument	equity	\N	\N	\N	\N	\N	\N	FAKE999	\N	\N	\N	\N	\N	\N	\N	\N	{}	t	\N
\.


--
-- Data for Name: market_data; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.market_data (id, date, series_id, value, daily_chg, pct_chg, source) FROM stdin;
1497	2026-02-09	EQ.IHYG	93.75	\N	\N	yfinance
1498	2026-02-10	EQ.IHYG	93.7300033569336	-0.01999664306640625	-0.021329752604166665	yfinance
1499	2026-02-11	EQ.IHYG	93.69999694824219	-0.03000640869140625	-0.03201366437291027	yfinance
1500	2026-02-12	EQ.IHYG	93.5999984741211	-0.09999847412109375	-0.10672196091567719	yfinance
1501	2026-02-13	EQ.IHYG	93.51000213623047	-0.089996337890625	-0.0961499352112784	yfinance
1502	2026-02-16	EQ.IHYG	93.54000091552734	0.029998779296875	0.03208082409534238	yfinance
1503	2026-02-17	EQ.IHYG	93.61000061035156	0.06999969482421875	0.0748339685044829	yfinance
1504	2026-02-18	EQ.IHYG	93.73999786376953	0.12999725341796875	0.1388711169430261	yfinance
1505	2026-02-19	EQ.IHYG	93.66000366210938	-0.07999420166015625	-0.0853362529156553	yfinance
1506	2026-02-20	EQ.IHYG	93.75	0.089996337890625	0.09608833479795546	yfinance
1507	2026-02-23	EQ.IHYG	93.73999786376953	-0.01000213623046875	-0.0106689453125	yfinance
1508	2026-02-24	EQ.IHYG	93.69999694824219	-0.04000091552734375	-0.042672195902411135	yfinance
1509	2026-02-25	EQ.IHYG	93.76000213623047	0.06000518798828125	0.0640396904403602	yfinance
1510	2026-02-26	EQ.IHYG	93.76000213623047	0	0	yfinance
1511	2026-02-27	EQ.IHYG	93.61000061035156	-0.15000152587890625	-0.15998455893906502	yfinance
1512	2026-03-02	EQ.IHYG	93.25	-0.3600006103515625	-0.3845749471256311	yfinance
1513	2026-03-03	EQ.IHYG	92.75	-0.5	-0.5361930294906166	yfinance
1514	2026-03-04	EQ.IHYG	93.30999755859375	0.55999755859375	0.6037709526617251	yfinance
1515	2026-03-05	EQ.IHYG	93.02999877929688	-0.279998779296875	-0.30007371838269586	yfinance
1516	2026-03-06	EQ.IHYG	92.5199966430664	-0.5100021362304688	-0.5482125582312336	yfinance
2221	2026-02-05	EQ.XLF	53.290000915527344	-0.6699981689453125	-1.2416571169626074	yfinance
2222	2026-02-06	EQ.XLF	54.2599983215332	0.9699974060058594	1.8202240370448688	yfinance
2223	2025-12-09	EQ.XLU	42.432106018066406	\N	\N	yfinance
2224	2025-12-10	EQ.XLU	42.412254333496094	-0.0198516845703125	-0.04678458467713153	yfinance
2225	2025-12-11	EQ.XLU	42.71995162963867	0.3076972961425781	0.7254914905562254	yfinance
2226	2025-12-12	EQ.XLU	42.511512756347656	-0.20843887329101562	-0.4879192633411196	yfinance
2227	2025-12-15	EQ.XLU	42.89861297607422	0.3871002197265625	0.9105773815794457	yfinance
2228	2025-12-16	EQ.XLU	42.71995162963867	-0.17866134643554688	-0.4164734802386068	yfinance
2229	2025-12-17	EQ.XLU	42.44203186035156	-0.2779197692871094	-0.6505619943031289	yfinance
2230	2025-12-18	EQ.XLU	42.858909606933594	0.41687774658203125	0.982228532209999	yfinance
2231	2025-12-19	EQ.XLU	42.3129997253418	-0.5459098815917969	-1.273737214965173	yfinance
2232	2025-12-22	EQ.XLU	42.470001220703125	0.15700149536132812	0.3710478963449569	yfinance
2233	2025-12-23	EQ.XLU	42.619998931884766	0.14999771118164062	0.353185087992228	yfinance
2234	2025-12-24	EQ.XLU	42.810001373291016	0.19000244140625	0.4458058333363914	yfinance
2235	2025-12-26	EQ.XLU	42.779998779296875	-0.030002593994140625	-0.07008314186333832	yfinance
2236	2025-12-29	EQ.XLU	42.86000061035156	0.0800018310546875	0.18700755805865968	yfinance
2237	2025-12-30	EQ.XLU	42.959999084472656	0.09999847412109375	0.2333142153454428	yfinance
2238	2025-12-31	EQ.XLU	42.689998626708984	-0.2700004577636719	-0.6284926990635344	yfinance
2239	2026-01-02	EQ.XLU	43.18000030517578	0.4900016784667969	1.1478137602005625	yfinance
2240	2026-01-05	EQ.XLU	42.70000076293945	-0.4799995422363281	-1.1116246846779037	yfinance
2241	2026-01-06	EQ.XLU	42.90999984741211	0.20999908447265625	0.49180112580916024	yfinance
2242	2026-01-07	EQ.XLU	41.869998931884766	-1.0400009155273438	-2.4236796066781294	yfinance
2243	2026-01-08	EQ.XLU	41.9900016784668	0.12000274658203125	0.2866079523366001	yfinance
2244	2026-01-09	EQ.XLU	42.5099983215332	0.5199966430664062	1.2383820487748862	yfinance
2245	2026-01-12	EQ.XLU	42.58000183105469	0.07000350952148438	0.1646753994013321	yfinance
2246	2026-01-13	EQ.XLU	42.849998474121094	0.26999664306640625	0.634092605579671	yfinance
2247	2026-01-14	EQ.XLU	43.16999816894531	0.31999969482421875	0.7467904462528276	yfinance
2248	2026-01-15	EQ.XLU	43.61000061035156	0.44000244140625	1.0192320131316783	yfinance
2249	2026-01-16	EQ.XLU	43.38999938964844	-0.220001220703125	-0.5044742435772955	yfinance
2250	2026-01-20	EQ.XLU	42.959999084472656	-0.43000030517578125	-0.9910124711326144	yfinance
2251	2026-01-21	EQ.XLU	43.02000045776367	0.060001373291015625	0.1396680041194469	yfinance
2252	2026-01-22	EQ.XLU	42.709999084472656	-0.3100013732910156	-0.7205982566071096	yfinance
2253	2026-01-23	EQ.XLU	42.560001373291016	-0.14999771118164062	-0.35120045515564696	yfinance
2254	2026-01-26	EQ.XLU	42.869998931884766	0.30999755859375	0.7283776987570595	yfinance
2255	2026-01-27	EQ.XLU	43.43000030517578	0.5600013732910156	1.3062780201622817	yfinance
2256	2026-01-28	EQ.XLU	43.33000183105469	-0.09999847412109375	-0.23025206865857747	yfinance
2257	2026-01-29	EQ.XLU	43.33000183105469	0	0	yfinance
2258	2026-01-30	EQ.XLU	43.25	-0.0800018310546875	-0.18463380492485937	yfinance
2259	2026-02-02	EQ.XLU	42.619998931884766	-0.6300010681152344	-1.4566498684745304	yfinance
2260	2026-02-03	EQ.XLU	43.2400016784668	0.6200027465820312	1.4547225765371767	yfinance
2261	2026-02-04	EQ.XLU	43.08000183105469	-0.15999984741210938	-0.3700273848319209	yfinance
2262	2026-02-05	EQ.XLU	43.099998474121094	0.01999664306640625	0.046417461041033316	yfinance
2263	2026-02-06	EQ.XLU	43.349998474121094	0.25	0.5800464242478098	yfinance
2264	2025-12-09	EQ.EEM	53.760650634765625	\N	\N	yfinance
2265	2025-12-10	EQ.EEM	54.36204528808594	0.6013946533203125	1.1186521111993502	yfinance
2266	2025-12-11	EQ.EEM	54.105712890625	-0.2563323974609375	-0.47152824383727826	yfinance
2267	2025-12-12	EQ.EEM	53.47474670410156	-0.6309661865234375	-1.1661729470212123	yfinance
2268	2025-12-15	EQ.EEM	53.31700134277344	-0.157745361328125	-0.2949903852766184	yfinance
2269	2025-12-16	EQ.EEM	52.97999954223633	-0.3370018005371094	-0.6320719321226164	yfinance
2270	2025-12-17	EQ.EEM	52.599998474121094	-0.3800010681152344	-0.7172538153993239	yfinance
2271	2025-12-18	EQ.EEM	53.20000076293945	0.6000022888183594	1.1406887951024507	yfinance
2272	2025-12-19	EQ.EEM	53.720001220703125	0.5200004577636719	0.9774444554630873	yfinance
2273	2025-12-22	EQ.EEM	54.0099983215332	0.2899971008300781	0.5398307785561186	yfinance
2274	2025-12-23	EQ.EEM	54.310001373291016	0.3000030517578125	0.5554583615645189	yfinance
2275	2025-12-24	EQ.EEM	54.41999816894531	0.10999679565429688	0.2025350632901879	yfinance
2276	2025-12-26	EQ.EEM	54.79999923706055	0.3800010681152344	0.6982746800827373	yfinance
2277	2025-12-29	EQ.EEM	54.65999984741211	-0.1399993896484375	-0.25547334233128544	yfinance
2278	2025-12-30	EQ.EEM	54.880001068115234	0.220001220703125	0.4024903426953467	yfinance
2279	2025-12-31	EQ.EEM	54.709999084472656	-0.17000198364257812	-0.30977037232848686	yfinance
2280	2026-01-02	EQ.EEM	56.2400016784668	1.5300025939941406	2.796568487657631	yfinance
2281	2026-01-05	EQ.EEM	56.86000061035156	0.6199989318847656	1.1024162755709006	yfinance
2282	2026-01-06	EQ.EEM	57.279998779296875	0.4199981689453125	0.7386531207121555	yfinance
2283	2026-01-07	EQ.EEM	56.849998474121094	-0.43000030517578125	-0.7506988727995563	yfinance
2284	2026-01-08	EQ.EEM	56.869998931884766	0.020000457763671875	0.03518110518996119	yfinance
2285	2026-01-09	EQ.EEM	57.13999938964844	0.2700004577636719	0.4747678263315269	yfinance
2286	2026-01-12	EQ.EEM	57.939998626708984	0.7999992370605469	1.4000686832444662	yfinance
2287	2026-01-13	EQ.EEM	57.5099983215332	-0.43000030517578125	-0.7421475929713971	yfinance
2288	2026-01-14	EQ.EEM	57.75	0.24000167846679688	0.4173216579228001	yfinance
2289	2026-01-15	EQ.EEM	58.09000015258789	0.3400001525878906	0.5887448529660444	yfinance
2290	2026-01-16	EQ.EEM	57.869998931884766	-0.220001220703125	-0.3787247721212547	yfinance
2291	2026-01-20	EQ.EEM	57.310001373291016	-0.55999755859375	-0.9676819922752873	yfinance
2292	2026-01-21	EQ.EEM	58.2599983215332	0.9499969482421875	1.6576460050216084	yfinance
2293	2026-01-22	EQ.EEM	58.70000076293945	0.44000244140625	0.7552393650578304	yfinance
2294	2026-01-23	EQ.EEM	59.06999969482422	0.3699989318847656	0.6303218519178732	yfinance
2295	2026-01-26	EQ.EEM	59.16999816894531	0.09999847412109375	0.16928808978791265	yfinance
2296	2026-01-27	EQ.EEM	60.34000015258789	1.1700019836425781	1.9773568021785746	yfinance
2297	2026-01-28	EQ.EEM	60.75	0.4099998474121094	0.6794826754645361	yfinance
1558	2025-12-09	RATES.US2Y	3.61	\N	\N	fred
5355	2025-12-26	EQ.SHEL	2697.7434	0	0	yfinance_direct
5775	2025-11-07	EQ.LVMH	598.038	3.172607421875	0.5333319652893028	yfinance_direct
5776	2025-11-10	EQ.LVMH	612.6122	14.57421875	2.437005364730761	yfinance_direct
5777	2025-11-11	EQ.LVMH	627.4839	14.87164306640625	2.4275784920233945	yfinance_direct
5778	2025-11-12	EQ.LVMH	641.6615	14.1776123046875	2.259438466033817	yfinance_direct
5779	2025-11-13	EQ.LVMH	631.3505	-10.31103515625	-1.6069275111476458	yfinance_direct
5780	2025-11-14	EQ.LVMH	631.5488	0.19830322265625	0.03140937308283432	yfinance_direct
5781	2025-11-17	EQ.LVMH	618.66	-12.88873291015625	-2.0408135652844535	yfinance_direct
5782	2025-11-18	EQ.LVMH	606.0687	-12.59136962890625	-2.0352647549961396	yfinance_direct
5783	2025-11-19	EQ.LVMH	604.3832	-1.6854248046875	-0.278091395128758	yfinance_direct
5784	2025-11-20	EQ.LVMH	614.2977	9.9144287109375	1.6404208553338824	yfinance_direct
5785	2025-11-21	EQ.LVMH	617.6686	3.37091064453125	0.5487422169447869	yfinance_direct
5786	2025-11-24	EQ.LVMH	616.3797	-1.28887939453125	-0.20866844099565587	yfinance_direct
5787	2025-11-25	EQ.LVMH	614.0002	-2.37945556640625	-0.3860373025810582	yfinance_direct
5788	2025-11-26	EQ.LVMH	620.048	6.04779052734375	0.9849817789255829	yfinance_direct
5789	2025-11-27	EQ.LVMH	622.0309	1.98291015625	0.31979944220157625	yfinance_direct
5790	2025-11-28	EQ.LVMH	630.0616	8.0306396484375	1.29103539225157	yfinance_direct
5791	2025-12-01	EQ.LVMH	637.2	7.138427734375	1.1329730157012607	yfinance_direct
5792	2025-12-02	EQ.LVMH	636.2	-1	-0.15693659460808237	yfinance_direct
5793	2025-12-03	EQ.LVMH	630.3	-5.9000244140625	-0.9273851463150433	yfinance_direct
5794	2025-12-04	EQ.LVMH	633.1	2.79998779296875	0.4442309768675494	yfinance_direct
5795	2025-12-05	EQ.LVMH	628.1	-5	-0.7897646805897398	yfinance_direct
5796	2025-12-08	EQ.LVMH	625.2	-2.89996337890625	-0.4617041062931029	yfinance_direct
5797	2025-12-09	EQ.LVMH	616.3	-8.9000244140625	-1.423548342976569	yfinance_direct
5798	2025-12-10	EQ.LVMH	618.8	2.5	0.40564660871611363	yfinance_direct
5799	2025-12-11	EQ.LVMH	625.2	6.4000244140625	1.0342638235803827	yfinance_direct
5800	2025-12-12	EQ.LVMH	624.5	-0.70001220703125	-0.11196612177919234	yfinance_direct
5801	2025-12-15	EQ.LVMH	626.1	1.5999755859375	0.2562010545936749	yfinance_direct
5802	2025-12-16	EQ.LVMH	636.5	10.4000244140625	1.6610804695096189	yfinance_direct
5803	2025-12-17	EQ.LVMH	631.7	-4.79998779296875	-0.7541221984239984	yfinance_direct
5804	2025-12-18	EQ.LVMH	637.4	5.70001220703125	0.9023289689541983	yfinance_direct
5805	2025-12-19	EQ.LVMH	631.7	-5.70001220703125	-0.8942598036878102	yfinance_direct
5806	2025-12-22	EQ.LVMH	627.7	-4	-0.6332119554699412	yfinance_direct
5807	2025-12-23	EQ.LVMH	627.3	-0.4000244140625	-0.06372859746425524	yfinance_direct
5808	2025-12-24	EQ.LVMH	632.1	4.79998779296875	0.7651821913557755	yfinance_direct
5809	2025-12-29	EQ.LVMH	633.2	1.10003662109375	0.17402889789294002	yfinance_direct
5810	2025-12-30	EQ.LVMH	639.3	6.0999755859375	0.9633568332817799	yfinance_direct
5811	2025-12-31	EQ.LVMH	645	5.70001220703125	0.8916021141669637	yfinance_direct
5812	2026-01-02	EQ.LVMH	641.8	-3.20001220703125	-0.4961259235707364	yfinance_direct
5813	2026-01-05	EQ.LVMH	642.8	1	0.15581178233405935	yfinance_direct
5814	2026-01-06	EQ.LVMH	644.4	1.60003662109375	0.24891671616040625	yfinance_direct
5815	2026-01-07	EQ.LVMH	629.3	-15.10003662109375	-2.3432706469593714	yfinance_direct
5816	2026-01-08	EQ.LVMH	634.5	5.20001220703125	0.8263169089305599	yfinance_direct
5817	2026-01-09	EQ.LVMH	652.1	17.5999755859375	2.7738338196907013	yfinance_direct
5818	2026-01-12	EQ.LVMH	648.3	-3.79998779296875	-0.5827308595670949	yfinance_direct
5819	2026-01-13	EQ.LVMH	646.6	-1.70001220703125	-0.2622261667501589	yfinance_direct
5820	2026-01-14	EQ.LVMH	637.9	-8.699951171875	-1.345492035317703	yfinance_direct
5821	2026-01-15	EQ.LVMH	625.7	-12.20001220703125	-1.912527314642677	yfinance_direct
5822	2026-01-16	EQ.LVMH	609.2	-16.5	-2.637046456463947	yfinance_direct
5823	2026-01-19	EQ.LVMH	582.8	-26.4000244140625	-4.333556120332231	yfinance_direct
5824	2026-01-20	EQ.LVMH	570	-12.79998779296875	-2.1962917057430964	yfinance_direct
5825	2026-01-21	EQ.LVMH	585.2	15.20001220703125	2.6666688082510963	yfinance_direct
5826	2026-01-22	EQ.LVMH	595.7	10.5	1.794258335778251	yfinance_direct
5827	2026-01-23	EQ.LVMH	591.4	-4.29998779296875	-0.7218377882917216	yfinance_direct
5828	2026-01-26	EQ.LVMH	588	-3.4000244140625	-0.5749111047858206	yfinance_direct
5829	2026-01-27	EQ.LVMH	589.3	1.29998779296875	0.22108635934842688	yfinance_direct
5830	2026-01-28	EQ.LVMH	542.8	-46.5	-7.8907179642325485	yfinance_direct
5831	2026-01-29	EQ.LVMH	542.4	-0.39996337890625	-0.0736852225315085	yfinance_direct
5832	2026-01-30	EQ.LVMH	546.9	4.5	0.8296459803557729	yfinance_direct
5833	2026-02-02	EQ.LVMH	538.3	-8.60003662109375	-1.5725061688025437	yfinance_direct
5834	2026-02-03	EQ.LVMH	529	-9.29998779296875	-1.7276589269672329	yfinance_direct
5835	2026-02-04	EQ.LVMH	536.1	7.0999755859375	1.3421503943171078	yfinance_direct
5836	2026-02-05	EQ.LVMH	538.2	2.10003662109375	0.39172481192495623	yfinance_direct
5837	2026-02-06	EQ.LVMH	536.2	-2	-0.3716090588326953	yfinance_direct
5838	2026-02-09	EQ.LVMH	535.4	-0.79998779296875	-0.14919578044691803	yfinance_direct
5839	2026-02-10	EQ.LVMH	537.7	2.29998779296875	0.4295830571703537	yfinance_direct
5840	2026-02-11	EQ.LVMH	525.1	-12.60003662109375	-2.343320873171627	yfinance_direct
5841	2026-02-12	EQ.LVMH	524.5	-0.5999755859375	-0.11425930562423126	yfinance_direct
5842	2026-02-13	EQ.LVMH	514.2	-10.29998779296875	-1.9637726964668731	yfinance_direct
5843	2026-02-16	EQ.LVMH	518.3	4.0999755859375	0.7973503478422197	yfinance_direct
5844	2026-02-17	EQ.LVMH	527.7	9.4000244140625	1.8136262078820022	yfinance_direct
5845	2026-02-18	EQ.LVMH	533.9	6.20001220703125	1.174912272808289	yfinance_direct
5846	2026-02-19	EQ.LVMH	531.5	-2.4000244140625	-0.44952693469089966	yfinance_direct
5847	2026-02-20	EQ.LVMH	554.7	23.20001220703125	4.365007000382173	yfinance_direct
5848	2026-02-23	EQ.LVMH	558	3.29998779296875	0.5949139571565563	yfinance_direct
5849	2026-02-24	EQ.LVMH	561.8	3.79998779296875	0.6810013965893817	yfinance_direct
5850	2026-02-25	EQ.LVMH	553	-8.79998779296875	-1.5663915956174193	yfinance_direct
5851	2026-02-26	EQ.LVMH	551.6	-1.4000244140625	-0.2531689718015371	yfinance_direct
5852	2026-02-27	EQ.LVMH	544.1	-7.5	-1.3596809883889351	yfinance_direct
5853	2026-03-02	EQ.LVMH	520.5	-23.5999755859375	-4.337433678529916	yfinance_direct
5854	2026-03-03	EQ.LVMH	502.2	-18.29998779296875	-3.5158477988412584	yfinance_direct
5855	2026-03-04	EQ.LVMH	507.4	5.199981689453125	1.0354403749614884	yfinance_direct
5856	2026-03-05	EQ.LVMH	505.8	-1.600006103515625	-0.3153342772491332	yfinance_direct
5857	2026-03-06	EQ.LVMH	502.2	-3.5999755859375	-0.711738962597805	yfinance_direct
5858	2026-03-09	EQ.LVMH	497.7	-4.5	-0.8960573258896858	yfinance_direct
5859	2026-03-10	EQ.LVMH	504.5	6.79998779296875	1.366282424389437	yfinance_direct
5860	2026-03-11	EQ.LVMH	500.3	-4.20001220703125	-0.832509852731665	yfinance_direct
5861	2026-03-12	EQ.LVMH	495	-5.29998779296875	-1.0593619672767132	yfinance_direct
5862	2026-03-13	EQ.LVMH	473.7	-21.29998779296875	-4.303027836963384	yfinance_direct
5863	2026-03-16	EQ.LVMH	479	5.29998779296875	1.1188489880495047	yfinance_direct
5864	2026-03-17	EQ.LVMH	472.25	-6.75	-1.4091858037578289	yfinance_direct
5865	2026-03-18	EQ.LVMH	468.55	-3.70001220703125	-0.7834859093766543	yfinance_direct
5866	2025-12-26	EQ.LVMH	632.1	0	0	yfinance_direct
5868	2024-03-20	EQ.ASML	954.4818	18.68817138671875	1.9970397943705218	yfinance_direct
5869	2024-03-21	EQ.ASML	974.0153	19.53350830078125	2.0465039841465433	yfinance_direct
5870	2024-03-22	EQ.ASML	963.3688	-10.64654541015625	-1.0930572849796285	yfinance_direct
5871	2024-03-25	EQ.ASML	962.3561	-1.01263427734375	-0.1051138779082446	yfinance_direct
5356	2024-03-19	EQ.LVMH	824.4221	\N	\N	yfinance_direct
5357	2024-03-20	EQ.LVMH	811.0045	-13.41766357421875	-1.6275234813211077	yfinance_direct
5358	2024-03-21	EQ.LVMH	812.6337	1.6292724609375	0.20089562390870155	yfinance_direct
5359	2024-03-22	EQ.LVMH	794.1364	-18.497314453125	-2.2762179091467143	yfinance_direct
5360	2024-03-25	EQ.LVMH	791.1653	-2.9710693359375	-0.37412581581109283	yfinance_direct
5361	2024-03-26	EQ.LVMH	787.6193	-3.54608154296875	-0.44820991829247137	yfinance_direct
5362	2024-03-27	EQ.LVMH	795.7657	8.14642333984375	1.0343098151213148	yfinance_direct
5363	2024-03-28	EQ.LVMH	799.0243	3.25860595703125	0.40949314782181845	yfinance_direct
5364	2024-04-02	EQ.LVMH	787.6193	-11.405029296875	-1.427369531962429	yfinance_direct
5365	2024-04-03	EQ.LVMH	782.0605	-5.55877685546875	-0.7057695410401792	yfinance_direct
5366	2024-04-04	EQ.LVMH	785.319	3.258544921875	0.41666149624932075	yfinance_direct
5367	2024-04-05	EQ.LVMH	766.5342	-18.7847900390625	-2.3919947566840736	yfinance_direct
5368	2024-04-08	EQ.LVMH	773.7223	7.18804931640625	0.9377336242187511	yfinance_direct
5369	2024-04-09	EQ.LVMH	762.1257	-11.59661865234375	-1.4988089139526117	yfinance_direct
5370	2024-04-10	EQ.LVMH	760.0171	-2.10858154296875	-0.2766711084711397	yfinance_direct
5371	2024-04-11	EQ.LVMH	757.6212	-2.39593505859375	-0.31524752411637535	yfinance_direct
5372	2024-04-12	EQ.LVMH	748.7079	-8.91326904296875	-1.176481013851355	yfinance_direct
5373	2024-04-15	EQ.LVMH	761.7422	13.0343017578125	1.7409061672820116	yfinance_direct
5374	2024-04-16	EQ.LVMH	749.283	-12.459228515625	-1.6356227500692286	yfinance_direct
5375	2024-04-17	EQ.LVMH	770.5596	21.276611328125	2.8395963197888086	yfinance_direct
5376	2024-04-18	EQ.LVMH	763.6591	-6.9005126953125	-0.8955196925935267	yfinance_direct
5377	2024-04-19	EQ.LVMH	763.4673	-0.19171142578125	-0.025104321603863236	yfinance_direct
5378	2024-04-22	EQ.LVMH	763.6591	0.19171142578125	0.02511062545603446	yfinance_direct
5379	2024-04-23	EQ.LVMH	773.6245	9.96539306640625	1.3049531681717803	yfinance_direct
5380	2024-04-24	EQ.LVMH	774.205	0.58050537109375	0.07503710237968837	yfinance_direct
5381	2024-04-25	EQ.LVMH	752.7261	-21.47882080078125	-2.774306807623181	yfinance_direct
5382	2024-04-26	EQ.LVMH	766.4649	13.73876953125	1.8252016088979957	yfinance_direct
5383	2024-04-29	EQ.LVMH	753.8871	-12.5777587890625	-1.6410090938981878	yfinance_direct
5384	2024-04-30	EQ.LVMH	749.2431	-4.64404296875	-0.616013019112288	yfinance_direct
5385	2024-05-02	EQ.LVMH	742.0835	-7.15960693359375	-0.9555786239025892	yfinance_direct
5386	2024-05-03	EQ.LVMH	756.5962	14.5126953125	1.9556687877972374	yfinance_direct
5387	2024-05-06	EQ.LVMH	756.306	-0.29022216796875	-0.038358925311179216	yfinance_direct
5388	2024-05-07	EQ.LVMH	763.7558	7.4498291015625	0.9850284679183012	yfinance_direct
5389	2024-05-08	EQ.LVMH	762.3046	-1.45123291015625	-0.19001268642552469	yfinance_direct
5390	2024-05-09	EQ.LVMH	763.3688	1.06427001953125	0.13961217967143538	yfinance_direct
5391	2024-05-10	EQ.LVMH	762.7883	-0.58056640625	-0.07605319726058174	yfinance_direct
5392	2024-05-13	EQ.LVMH	757.1767	-5.611572265625	-0.7356657795308719	yfinance_direct
5393	2024-05-14	EQ.LVMH	766.1746	8.9979248046875	1.188352050846784	yfinance_direct
5394	2024-05-15	EQ.LVMH	763.3688	-2.8057861328125	-0.36620713526362814	yfinance_direct
5395	2024-05-16	EQ.LVMH	760.4662	-2.902587890625	-0.38023400430237864	yfinance_direct
5396	2024-05-17	EQ.LVMH	757.7573	-2.708984375	-0.35622677320616697	yfinance_direct
5397	2024-05-20	EQ.LVMH	753.7903	-3.9669189453125	-0.5235078748893988	yfinance_direct
5398	2024-05-21	EQ.LVMH	743.1477	-10.64263916015625	-1.411883190267027	yfinance_direct
5399	2024-05-22	EQ.LVMH	727.474	-15.6737060546875	-2.109097013633349	yfinance_direct
5400	2024-05-23	EQ.LVMH	728.3447	0.8707275390625	0.11969191204515438	yfinance_direct
5401	2024-05-24	EQ.LVMH	725.6357	-2.708984375	-0.3719371166158281	yfinance_direct
5402	2024-05-27	EQ.LVMH	731.6343	5.99859619140625	0.8266676849906669	yfinance_direct
5403	2024-05-28	EQ.LVMH	721.1852	-10.44915771484375	-1.4281939989306836	yfinance_direct
5404	2024-05-29	EQ.LVMH	700.6739	-20.51129150390625	-2.8441088438644275	yfinance_direct
5405	2024-05-30	EQ.LVMH	710.5425	9.86865234375	1.408451563048652	yfinance_direct
5406	2024-05-31	EQ.LVMH	711.0263	0.4837646484375	0.06808384018972079	yfinance_direct
5407	2024-06-03	EQ.LVMH	714.0256	2.999267578125	0.42182230842558727	yfinance_direct
5408	2024-06-04	EQ.LVMH	711.123	-2.902587890625	-0.40651035444854705	yfinance_direct
5409	2024-06-05	EQ.LVMH	728.1512	17.02825927734375	2.394558974525791	yfinance_direct
5410	2024-06-06	EQ.LVMH	737.9232	9.77197265625	1.3420251248320414	yfinance_direct
5411	2024-06-07	EQ.LVMH	737.7297	-0.19354248046875	-0.026227997142132586	yfinance_direct
5412	2024-06-10	EQ.LVMH	722.0559	-15.67376708984375	-2.124594904443738	yfinance_direct
5413	2024-06-11	EQ.LVMH	712.671	-9.3848876953125	-1.299745295162434	yfinance_direct
5414	2024-06-12	EQ.LVMH	711.5101	-1.16094970703125	-0.16290120877989642	yfinance_direct
5415	2024-06-13	EQ.LVMH	707.7368	-3.7733154296875	-0.530324950346909	yfinance_direct
5416	2024-06-14	EQ.LVMH	688.2897	-19.447021484375	-2.7477761098020372	yfinance_direct
5417	2024-06-17	EQ.LVMH	694.0948	5.8050537109375	0.84340262902903	yfinance_direct
5418	2024-06-18	EQ.LVMH	687.0319	-7.06292724609375	-1.017573877847343	yfinance_direct
5419	2024-06-19	EQ.LVMH	684.0326	-2.999267578125	-0.4365543654103958	yfinance_direct
5420	2024-06-20	EQ.LVMH	690.4182	6.3856201171875	0.9335257098344901	yfinance_direct
5421	2024-06-21	EQ.LVMH	693.998	3.57977294921875	0.5184934120192238	yfinance_direct
5422	2024-06-24	EQ.LVMH	702.8992	8.90118408203125	1.2825950886960364	yfinance_direct
5423	2024-06-25	EQ.LVMH	712.8646	9.96539306640625	1.4177557027864853	yfinance_direct
5424	2024-06-26	EQ.LVMH	703.3829	-9.481689453125	-1.3300828720365034	yfinance_direct
5425	2024-06-27	EQ.LVMH	692.2565	-11.1263427734375	-1.5818330516802648	yfinance_direct
5426	2024-06-28	EQ.LVMH	690.4182	-1.83831787109375	-0.2655544280775469	yfinance_direct
5427	2024-07-01	EQ.LVMH	688.8702	-1.54803466796875	-0.224216951271821	yfinance_direct
5428	2024-07-02	EQ.LVMH	686.5481	-2.32208251953125	-0.3370856502341879	yfinance_direct
5429	2024-07-03	EQ.LVMH	691.5792	5.0311279296875	0.732815073142821	yfinance_direct
5430	2024-07-04	EQ.LVMH	696.4167	4.8375244140625	0.6994895521371154	yfinance_direct
5431	2024-07-05	EQ.LVMH	693.1273	-3.28948974609375	-0.4723450082611078	yfinance_direct
5432	2024-07-08	EQ.LVMH	673.0997	-20.027587890625	-2.889453221003475	yfinance_direct
5433	2024-07-09	EQ.LVMH	664.5856	-8.51409912109375	-1.2649091205030076	yfinance_direct
5434	2024-07-10	EQ.LVMH	674.9379	10.35235595703125	1.55771602698977	yfinance_direct
5435	2024-07-11	EQ.LVMH	686.9352	11.99725341796875	1.7775343381457875	yfinance_direct
5436	2024-07-12	EQ.LVMH	701.2544	14.3192138671875	2.084507282527744	yfinance_direct
5437	2024-07-15	EQ.LVMH	682.6781	-18.5762939453125	-2.649009273978202	yfinance_direct
5438	2024-07-16	EQ.LVMH	669.6166	-13.06146240234375	-1.9132681114471366	yfinance_direct
5439	2024-07-17	EQ.LVMH	667.7784	-1.8382568359375	-0.2745237694397748	yfinance_direct
5440	2024-07-18	EQ.LVMH	667.8751	0.09674072265625	0.01448695036533164	yfinance_direct
5441	2024-07-19	EQ.LVMH	657.7162	-10.15887451171875	-1.521073951703391	yfinance_direct
5442	2024-07-22	EQ.LVMH	669.6166	11.900390625	1.8093502584395003	yfinance_direct
5443	2024-07-23	EQ.LVMH	669.1329	-0.48370361328125	-0.07223590121555931	yfinance_direct
5444	2024-07-24	EQ.LVMH	637.9789	-31.15399169921875	-4.655874802997772	yfinance_direct
5445	2024-07-25	EQ.LVMH	631.3998	-6.57916259765625	-1.03125074442866	yfinance_direct
5446	2024-07-26	EQ.LVMH	641.5587	10.158935546875	1.6089545584693608	yfinance_direct
5447	2024-07-29	EQ.LVMH	633.4316	-8.1270751953125	-1.2667702885029042	yfinance_direct
5448	2024-07-30	EQ.LVMH	631.2064	-2.22528076171875	-0.3513055899012386	yfinance_direct
5449	2024-07-31	EQ.LVMH	631.7869	0.58050537109375	0.09196760489223951	yfinance_direct
5450	2024-08-01	EQ.LVMH	621.1442	-10.64263916015625	-1.6845299808833685	yfinance_direct
5451	2024-08-02	EQ.LVMH	610.0178	-11.12640380859375	-1.7912754142327467	yfinance_direct
5452	2024-08-05	EQ.LVMH	604.0192	-5.99859619140625	-0.9833476945193632	yfinance_direct
5453	2024-08-06	EQ.LVMH	601.6972	-2.322021484375	-0.3844284062722338	yfinance_direct
5454	2024-08-07	EQ.LVMH	610.8886	9.19140625	1.5275800153111008	yfinance_direct
5455	2024-08-08	EQ.LVMH	612.7268	1.83819580078125	0.3009052334850565	yfinance_direct
5456	2024-08-09	EQ.LVMH	615.3391	2.6123046875	0.426340851940588	yfinance_direct
5457	2024-08-12	EQ.LVMH	614.4683	-0.87078857421875	-0.14151360740572339	yfinance_direct
5458	2024-08-13	EQ.LVMH	613.5976	-0.8707275390625	-0.14170421921183807	yfinance_direct
5459	2024-08-14	EQ.LVMH	623.2728	9.6751708984375	1.576794135747852	yfinance_direct
5460	2024-08-15	EQ.LVMH	634.6894	11.4166259765625	1.8317222566544007	yfinance_direct
5461	2024-08-16	EQ.LVMH	636.7211	2.03173828125	0.32011536770137106	yfinance_direct
5462	2024-08-19	EQ.LVMH	652.5884	15.8673095703125	2.4920343951934996	yfinance_direct
5463	2024-08-20	EQ.LVMH	655.7812	3.19281005859375	0.4892532357576579	yfinance_direct
5464	2024-08-21	EQ.LVMH	656.7487	0.96746826171875	0.14752911305694544	yfinance_direct
5465	2024-08-22	EQ.LVMH	655.9747	-0.77398681640625	-0.11785128693586747	yfinance_direct
5466	2024-08-23	EQ.LVMH	658.974	2.999267578125	0.45722303533197056	yfinance_direct
5467	2024-08-26	EQ.LVMH	659.8448	0.87078857421875	0.13214308538868147	yfinance_direct
5468	2024-08-27	EQ.LVMH	648.0411	-11.80364990234375	-1.7888524883735364	yfinance_direct
5469	2024-08-28	EQ.LVMH	644.558	-3.48309326171875	-0.5374802707905227	yfinance_direct
5470	2024-08-29	EQ.LVMH	655.3942	10.836181640625	1.6811801100314105	yfinance_direct
5471	2024-08-30	EQ.LVMH	652.3949	-2.99932861328125	-0.45763732635349724	yfinance_direct
5472	2024-09-02	EQ.LVMH	651.3306	-1.06427001953125	-0.1631327932933402	yfinance_direct
5473	2024-09-03	EQ.LVMH	649.1053	-2.22528076171875	-0.3416514851236496	yfinance_direct
5474	2024-09-04	EQ.LVMH	621.7247	-27.38067626953125	-4.218217645192611	yfinance_direct
5475	2024-09-05	EQ.LVMH	599.0848	-22.63983154296875	-3.641456197649852	yfinance_direct
5476	2024-09-06	EQ.LVMH	592.1188	-6.966064453125	-1.162784300516963	yfinance_direct
5477	2024-09-09	EQ.LVMH	596.1823	4.06353759765625	0.6862706898083695	yfinance_direct
5478	2024-09-10	EQ.LVMH	592.5058	-3.676513671875	-0.6166760733758121	yfinance_direct
5479	2024-09-11	EQ.LVMH	587.2812	-5.224609375	-0.8817819824951855	yfinance_direct
5480	2024-09-12	EQ.LVMH	587.0877	-0.1934814453125	-0.03294528225117088	yfinance_direct
5481	2024-09-13	EQ.LVMH	588.3454	1.2576904296875	0.21422530459738148	yfinance_direct
5482	2024-09-16	EQ.LVMH	583.9916	-4.353759765625	-0.7400006494145777	yfinance_direct
5483	2024-09-17	EQ.LVMH	587.9584	3.966796875	0.6792557659452187	yfinance_direct
5484	2024-09-18	EQ.LVMH	576.5418	-11.4166259765625	-1.9417403162903448	yfinance_direct
5485	2024-09-19	EQ.LVMH	594.0538	17.511962890625	3.0374142195355294	yfinance_direct
5486	2024-09-20	EQ.LVMH	572.6718	-21.38201904296875	-3.599340674492501	yfinance_direct
5487	2024-09-23	EQ.LVMH	575.7678	3.09600830078125	0.5406252857666924	yfinance_direct
5488	2024-09-24	EQ.LVMH	594.1505	18.38275146484375	3.1927371941697666	yfinance_direct
1769	2025-12-09	CM.WTI	58.25	\N	\N	yfinance
1770	2025-12-10	CM.WTI	58.459999084472656	0.20999908447265625	0.36051344973846566	yfinance
1771	2025-12-11	CM.WTI	57.599998474121094	-0.8600006103515625	-1.4710924115973585	yfinance
1772	2025-12-12	CM.WTI	57.439998626708984	-0.15999984741210938	-0.2777775202268367	yfinance
1773	2025-12-15	CM.WTI	56.81999969482422	-0.6199989318847656	-1.0793853529036694	yfinance
1774	2025-12-16	CM.WTI	55.27000045776367	-1.5499992370605469	-2.727911378714311	yfinance
1775	2025-12-17	CM.WTI	55.939998626708984	0.6699981689453125	1.21222754368767	yfinance
1776	2025-12-18	CM.WTI	56.150001525878906	0.21000289916992188	0.3754074085186952	yfinance
1777	2025-12-19	CM.WTI	56.65999984741211	0.5099983215332031	0.9082783751985307	yfinance
1778	2025-12-22	CM.WTI	58.0099983215332	1.3499984741210938	2.382630564342922	yfinance
1779	2025-12-23	CM.WTI	58.380001068115234	0.37000274658203125	0.6378258184584138	yfinance
1780	2025-12-24	CM.WTI	58.349998474121094	-0.030002593994140625	-0.05139190381160649	yfinance
1781	2025-12-26	CM.WTI	56.7400016784668	-1.6099967956542969	-2.7592062343726527	yfinance
1782	2025-12-29	CM.WTI	58.08000183105469	1.3400001525878906	2.3616498289537935	yfinance
1783	2025-12-30	CM.WTI	57.95000076293945	-0.13000106811523438	-0.2238310330867179	yfinance
1784	2025-12-31	CM.WTI	57.41999816894531	-0.5300025939941406	-0.9145860000283058	yfinance
1785	2026-01-02	CM.WTI	57.31999969482422	-0.09999847412109375	-0.17415269472296208	yfinance
1786	2026-01-05	CM.WTI	58.31999969482422	1	1.7445917748151982	yfinance
1787	2026-01-06	CM.WTI	57.130001068115234	-1.1899986267089844	-2.040464048244147	yfinance
1788	2026-01-07	CM.WTI	55.9900016784668	-1.1399993896484375	-1.9954478703566512	yfinance
1789	2026-01-08	CM.WTI	57.7599983215332	1.7699966430664062	3.1612727094222066	yfinance
1790	2026-01-09	CM.WTI	59.119998931884766	1.3600006103515625	2.354571762244231	yfinance
1791	2026-01-12	CM.WTI	59.5	0.3800010681152344	0.6427623054476936	yfinance
1792	2026-01-13	CM.WTI	61.150001525878906	1.6500015258789062	2.7731118081998423	yfinance
1793	2026-01-14	CM.WTI	62.02000045776367	0.8699989318847656	1.422729207155586	yfinance
1794	2026-01-15	CM.WTI	59.189998626708984	-2.8300018310546875	-4.563047097979226	yfinance
1795	2026-01-16	CM.WTI	59.439998626708984	0.25	0.4223686531514627	yfinance
1796	2026-01-20	CM.WTI	60.34000015258789	0.9000015258789062	1.514134499785295	yfinance
1797	2026-01-21	CM.WTI	60.619998931884766	0.279998779296875	0.46403509875507726	yfinance
1798	2026-01-22	CM.WTI	59.36000061035156	-1.2599983215332031	-2.0785192077436214	yfinance
1799	2026-01-23	CM.WTI	61.06999969482422	1.7099990844726562	2.8807261908525925	yfinance
1800	2026-01-26	CM.WTI	60.630001068115234	-0.4399986267089844	-0.7204824445844479	yfinance
1801	2026-01-27	CM.WTI	62.38999938964844	1.7599983215332031	2.9028505534016396	yfinance
1802	2026-01-28	CM.WTI	63.209999084472656	0.8199996948242188	1.3143127149321157	yfinance
1803	2026-01-29	CM.WTI	65.41999816894531	2.2099990844726562	3.4962808360735065	yfinance
1804	2026-01-30	CM.WTI	65.20999908447266	-0.20999908447265625	-0.3210013609757975	yfinance
1805	2026-02-02	CM.WTI	62.13999938964844	-3.0699996948242188	-4.707866489688734	yfinance
1806	2026-02-03	CM.WTI	63.209999084472656	1.0699996948242188	1.7219177749178802	yfinance
1807	2026-02-04	CM.WTI	65.13999938964844	1.9300003051757812	3.0533148760160005	yfinance
1808	2026-02-05	CM.WTI	63.290000915527344	-1.8499984741210938	-2.8400345278711834	yfinance
1809	2026-02-06	CM.WTI	63.54999923706055	0.2599983215332031	0.4108047365652922	yfinance
1810	2025-12-09	CM.BRENT	61.939998626708984	\N	\N	yfinance
1811	2025-12-10	CM.BRENT	62.209999084472656	0.2700004577636719	0.43590646391659055	yfinance
1812	2025-12-11	CM.BRENT	61.279998779296875	-0.9300003051757812	-1.494937017942997	yfinance
1813	2025-12-12	CM.BRENT	61.119998931884766	-0.15999984741210938	-0.2610963619440614	yfinance
1814	2025-12-15	CM.BRENT	60.560001373291016	-0.55999755859375	-0.9162263880564523	yfinance
1815	2025-12-16	CM.BRENT	58.91999816894531	-1.6400032043457031	-2.7080633539565926	yfinance
1816	2025-12-17	CM.BRENT	59.68000030517578	0.7600021362304688	1.2898882550051394	yfinance
1817	2025-12-18	CM.BRENT	59.81999969482422	0.1399993896484375	0.23458342649555244	yfinance
1818	2025-12-19	CM.BRENT	60.470001220703125	0.6500015258789062	1.0865956689985508	yfinance
1819	2025-12-22	CM.BRENT	62.06999969482422	1.5999984741210938	2.645937558825949	yfinance
1820	2025-12-23	CM.BRENT	62.380001068115234	0.3100013732910156	0.4994383354521999	yfinance
1821	2025-12-24	CM.BRENT	62.2400016784668	-0.1399993896484375	-0.22442992505813927	yfinance
1822	2025-12-26	CM.BRENT	60.63999938964844	-1.6000022888183594	-2.5706976954853022	yfinance
1823	2025-12-29	CM.BRENT	61.939998626708984	1.2999992370605469	2.14379823572766	yfinance
1824	2025-12-30	CM.BRENT	61.91999816894531	-0.020000457763671875	-0.03229005199726874	yfinance
1825	2025-12-31	CM.BRENT	60.849998474121094	-1.0699996948242188	-1.7280357339559078	yfinance
1826	2026-01-02	CM.BRENT	60.75	-0.09999847412109375	-0.16433603390084245	yfinance
1827	2026-01-05	CM.BRENT	61.7599983215332	1.0099983215332031	1.6625486774209104	yfinance
1828	2026-01-06	CM.BRENT	60.70000076293945	-1.05999755859375	-1.7163173371139355	yfinance
1829	2026-01-07	CM.BRENT	59.959999084472656	-0.7400016784667969	-1.2191131287738086	yfinance
1830	2026-01-08	CM.BRENT	61.9900016784668	2.0300025939941406	3.385594771497976	yfinance
1831	2026-01-09	CM.BRENT	63.34000015258789	1.3499984741210938	2.177768087704435	yfinance
1832	2026-01-12	CM.BRENT	63.869998931884766	0.529998779296875	0.8367520966531301	yfinance
1833	2026-01-13	CM.BRENT	65.47000122070312	1.6000022888183594	2.5050920863873958	yfinance
1834	2026-01-14	CM.BRENT	66.5199966430664	1.0499954223632812	1.6037809726376613	yfinance
1835	2026-01-15	CM.BRENT	63.7599983215332	-2.759998321533203	-4.149125767914311	yfinance
1836	2026-01-16	CM.BRENT	64.12999725341797	0.3699989318847656	0.580299469298776	yfinance
1837	2026-01-20	CM.BRENT	64.91999816894531	0.7900009155273438	1.2318742388301578	yfinance
1838	2026-01-21	CM.BRENT	65.23999786376953	0.31999969482421875	0.4929138999533916	yfinance
1839	2026-01-22	CM.BRENT	64.05999755859375	-1.1800003051757812	-1.8087068421427466	yfinance
1840	2026-01-23	CM.BRENT	65.87999725341797	1.8199996948242188	2.8410861133104475	yfinance
1841	2026-01-26	CM.BRENT	65.58999633789062	-0.29000091552734375	-0.4401957006947173	yfinance
1842	2026-01-27	CM.BRENT	67.56999969482422	1.9800033569335938	3.018758145271869	yfinance
1843	2026-01-28	CM.BRENT	68.4000015258789	0.8300018310546875	1.2283584946031376	yfinance
1844	2026-01-29	CM.BRENT	70.70999908447266	2.30999755859375	3.3771893378098397	yfinance
1845	2026-01-30	CM.BRENT	70.69000244140625	-0.01999664306640625	-0.02827979539713691	yfinance
1846	2026-02-02	CM.BRENT	66.30000305175781	-4.3899993896484375	-6.2102125308132985	yfinance
1847	2026-02-03	CM.BRENT	67.33000183105469	1.029998779296875	1.553542582030947	yfinance
1848	2026-02-04	CM.BRENT	69.45999908447266	2.1299972534179688	3.1635187813637455	yfinance
1849	2026-02-05	CM.BRENT	67.55000305175781	-1.9099960327148438	-2.7497783730057828	yfinance
1850	2026-02-06	CM.BRENT	68.05000305175781	0.5	0.7401924165967729	yfinance
1851	2025-12-09	CM.GOLD	4206.7001953125	\N	\N	yfinance
1852	2025-12-10	CM.GOLD	4196.39990234375	-10.30029296875	-0.24485445813865112	yfinance
1853	2025-12-11	CM.GOLD	4285.5	89.10009765625	2.1232508752677814	yfinance
1854	2025-12-12	CM.GOLD	4300.10009765625	14.60009765625	0.34068597961148056	yfinance
1855	2025-12-15	CM.GOLD	4306.7001953125	6.60009765625	0.15348707021604807	yfinance
1856	2025-12-16	CM.GOLD	4304.5	-2.2001953125	-0.05108772871849165	yfinance
1857	2025-12-17	CM.GOLD	4347.5	43	0.998954582413753	yfinance
1858	2025-12-18	CM.GOLD	4339.5	-8	-0.18401380103507764	yfinance
1859	2025-12-19	CM.GOLD	4361.39990234375	21.89990234375	0.5046641858220993	yfinance
1860	2025-12-22	CM.GOLD	4444.60009765625	83.2001953125	1.9076488553088076	yfinance
1861	2025-12-23	CM.GOLD	4482.7998046875	38.19970703125	0.8594633081026496	yfinance
1862	2025-12-24	CM.GOLD	4480.60009765625	-2.19970703125	-0.04906993680489249	yfinance
1863	2025-12-26	CM.GOLD	4529.10009765625	48.5	1.0824442919012074	yfinance
1864	2025-12-29	CM.GOLD	4325.10009765625	-204	-4.504206036549453	yfinance
1865	2025-12-30	CM.GOLD	4370.10009765625	45	1.0404383478751225	yfinance
1866	2025-12-31	CM.GOLD	4325.60009765625	-44.5	-1.0182833117224481	yfinance
1867	2026-01-02	CM.GOLD	4314.39990234375	-11.2001953125	-0.25892812695673434	yfinance
1868	2026-01-05	CM.GOLD	4436.89990234375	122.5	2.83932882377114	yfinance
1869	2026-01-06	CM.GOLD	4482.2001953125	45.30029296875	1.0209897443217177	yfinance
1870	2026-01-07	CM.GOLD	4449.2998046875	-32.900390625	-0.7340232294712614	yfinance
1871	2026-01-08	CM.GOLD	4449.7001953125	0.400390625	0.008998958096241882	yfinance
1872	2026-01-09	CM.GOLD	4490.2998046875	40.599609375	0.9124122433634815	yfinance
1873	2026-01-12	CM.GOLD	4604.2998046875	114	2.538805980861088	yfinance
1874	2026-01-13	CM.GOLD	4589.2001953125	-15.099609375	-0.3279458335798972	yfinance
1875	2026-01-14	CM.GOLD	4626.2998046875	37.099609375	0.8084112219138812	yfinance
1876	2026-01-15	CM.GOLD	4616.2998046875	-10	-0.21615546813173916	yfinance
1877	2026-01-16	CM.GOLD	4588.39990234375	-27.89990234375	-0.6043780413789368	yfinance
1878	2026-01-20	CM.GOLD	4759.60009765625	171.2001953125	3.73115244870115	yfinance
1879	2026-01-21	CM.GOLD	4831.7998046875	72.19970703125	1.5169280097040716	yfinance
1880	2026-01-22	CM.GOLD	4908.7998046875	77	1.5936090714126767	yfinance
1881	2026-01-23	CM.GOLD	4976.2001953125	67.400390625	1.373052340831626	yfinance
1882	2026-01-26	CM.GOLD	5079.7001953125	103.5	2.0799002439149317	yfinance
1883	2026-01-27	CM.GOLD	5079.89990234375	0.19970703125	0.003931472795073374	yfinance
1884	2026-01-28	CM.GOLD	5301.60009765625	221.7001953125	4.364263067668175	yfinance
1885	2026-01-29	CM.GOLD	5318.39990234375	16.7998046875	0.3168817786714414	yfinance
1886	2026-01-30	CM.GOLD	4713.89990234375	-604.5	-11.366200569716554	yfinance
1887	2026-02-02	CM.GOLD	4622.5	-91.39990234375	-1.938944488369513	yfinance
1888	2026-02-03	CM.GOLD	4903.7001953125	281.2001953125	6.083292489183342	yfinance
1889	2026-02-04	CM.GOLD	4920.39990234375	16.69970703125	0.34055318159975256	yfinance
1890	2026-02-05	CM.GOLD	4861.39990234375	-59	-1.1990895287168903	yfinance
1891	2026-02-06	CM.GOLD	4951.2001953125	89.80029296875	1.847210572523688	yfinance
1892	2025-12-09	CM.COPPER	5.240499973297119	\N	\N	yfinance
1893	2025-12-10	CM.COPPER	5.2754998207092285	0.034999847412109375	0.6678722944461505	yfinance
1894	2025-12-11	CM.COPPER	5.427000045776367	0.15150022506713867	2.8717700732813456	yfinance
1895	2025-12-12	CM.COPPER	5.2835001945495605	-0.14349985122680664	-2.644183711376366	yfinance
1896	2025-12-15	CM.COPPER	5.338500022888184	0.05499982833862305	1.0409733380034825	yfinance
1897	2025-12-16	CM.COPPER	5.2870001792907715	-0.05149984359741211	-0.9646875222742841	yfinance
1898	2025-12-17	CM.COPPER	5.363500118255615	0.07649993896484375	1.4469441341139861	yfinance
1899	2025-12-18	CM.COPPER	5.366499900817871	0.0029997825622558594	0.055929570170895906	yfinance
1900	2025-12-19	CM.COPPER	5.439499855041504	0.07299995422363281	1.3602898643957375	yfinance
1901	2025-12-22	CM.COPPER	5.4375	-0.0019998550415039062	-0.036765421358553325	yfinance
1902	2025-12-23	CM.COPPER	5.47599983215332	0.03849983215332031	0.7080428901760057	yfinance
1903	2025-12-24	CM.COPPER	5.498499870300293	0.022500038146972656	0.4108845660450832	yfinance
1904	2025-12-26	CM.COPPER	5.766499996185303	0.26800012588500977	4.874058965293261	yfinance
1905	2025-12-29	CM.COPPER	5.490499973297119	-0.2760000228881836	-4.786265899085496	yfinance
1906	2025-12-30	CM.COPPER	5.727499961853027	0.2369999885559082	4.3165465751489025	yfinance
1907	2025-12-31	CM.COPPER	5.630000114440918	-0.09749984741210938	-1.702310747472534	yfinance
1908	2026-01-02	CM.COPPER	5.639999866485596	0.009999752044677734	0.1776154856378853	yfinance
1909	2026-01-05	CM.COPPER	5.924499988555908	0.2845001220703125	5.0443285249152074	yfinance
1910	2026-01-06	CM.COPPER	6.010499954223633	0.08599996566772461	1.4515987143868156	yfinance
1911	2026-01-07	CM.COPPER	5.809000015258789	-0.20149993896484375	-3.352465526985786	yfinance
1912	2026-01-08	CM.COPPER	5.746500015258789	-0.0625	-1.0759166781860585	yfinance
1913	2026-01-09	CM.COPPER	5.855500221252441	0.10900020599365234	1.8968103315796059	yfinance
1914	2026-01-12	CM.COPPER	5.985000133514404	0.1294999122619629	2.211594353492552	yfinance
1915	2026-01-13	CM.COPPER	5.96999979019165	-0.015000343322753906	-0.2506322972117575	yfinance
1916	2026-01-14	CM.COPPER	6.008999824523926	0.03900003433227539	0.6532669296965486	yfinance
1917	2026-01-15	CM.COPPER	5.947999954223633	-0.06099987030029297	-1.015141821960792	yfinance
1918	2026-01-16	CM.COPPER	5.78849983215332	-0.1595001220703125	-2.681575711127109	yfinance
1919	2026-01-20	CM.COPPER	5.7729997634887695	-0.015500068664550781	-0.2677735011488246	yfinance
1920	2026-01-21	CM.COPPER	5.729499816894531	-0.04349994659423828	-0.7535068140718261	yfinance
1921	2026-01-22	CM.COPPER	5.742499828338623	0.013000011444091797	0.22689609668471872	yfinance
1922	2026-01-23	CM.COPPER	5.910999774932861	0.16849994659423828	2.934261238680566	yfinance
1923	2026-01-26	CM.COPPER	5.984000205993652	0.07300043106079102	1.2349929595729037	yfinance
1924	2026-01-27	CM.COPPER	5.828499794006348	-0.1555004119873047	-2.5986030520445746	yfinance
1925	2026-01-28	CM.COPPER	5.892499923706055	0.06400012969970703	1.0980549362894483	yfinance
1926	2026-01-29	CM.COPPER	6.17549991607666	0.28299999237060547	4.802715248787211	yfinance
1927	2026-01-30	CM.COPPER	5.896999835968018	-0.2785000801086426	-4.509757653524116	yfinance
1928	2026-02-02	CM.COPPER	5.801499843597412	-0.09549999237060547	-1.6194674415304395	yfinance
1929	2026-02-03	CM.COPPER	6.0625	0.2610001564025879	4.498839324983004	yfinance
1930	2026-02-04	CM.COPPER	5.826000213623047	-0.23649978637695312	-3.901027404155928	yfinance
1931	2026-02-05	CM.COPPER	5.798999786376953	-0.02700042724609375	-0.4634470692767593	yfinance
1932	2026-02-06	CM.COPPER	5.863500118255615	0.06450033187866211	1.112266498615618	yfinance
1933	2025-12-09	CM.NATGAS	4.573999881744385	\N	\N	yfinance
1934	2025-12-10	CM.NATGAS	4.59499979019165	0.020999908447265625	0.45911475710963284	yfinance
1935	2025-12-11	CM.NATGAS	4.230999946594238	-0.3639998435974121	-7.921650929656087	yfinance
1936	2025-12-12	CM.NATGAS	4.11299991607666	-0.11800003051757812	-2.78893954164577	yfinance
1937	2025-12-15	CM.NATGAS	4.01200008392334	-0.10099983215332031	-2.4556244642392993	yfinance
1938	2025-12-16	CM.NATGAS	3.885999917984009	-0.12600016593933105	-3.140582335584483	yfinance
1939	2025-12-17	CM.NATGAS	4.02400016784668	0.1380002498626709	3.551215974658669	yfinance
1940	2025-12-18	CM.NATGAS	3.9079999923706055	-0.11600017547607422	-2.8827080178316233	yfinance
1941	2025-12-19	CM.NATGAS	3.9839999675750732	0.07599997520446777	1.9447281308300604	yfinance
1942	2025-12-22	CM.NATGAS	3.9649999141693115	-0.01900005340576172	-0.4769089749096161	yfinance
1943	2025-12-23	CM.NATGAS	4.4079999923706055	0.44300007820129395	11.172763878712587	yfinance
1944	2025-12-24	CM.NATGAS	4.242000102996826	-0.1659998893737793	-3.765877714634595	yfinance
1945	2025-12-26	CM.NATGAS	4.366000175476074	0.12400007247924805	2.9231510954383593	yfinance
1946	2025-12-29	CM.NATGAS	4.686999797821045	0.3209996223449707	7.352258576351717	yfinance
1947	2025-12-30	CM.NATGAS	3.9719998836517334	-0.7149999141693115	-15.254959355912716	yfinance
1948	2025-12-31	CM.NATGAS	3.686000108718872	-0.28599977493286133	-7.200397364310143	yfinance
1949	2026-01-02	CM.NATGAS	3.618000030517578	-0.06800007820129395	-1.8448202983078168	yfinance
1950	2026-01-05	CM.NATGAS	3.5230000019073486	-0.09500002861022949	-2.625760857073269	yfinance
1951	2026-01-06	CM.NATGAS	3.3499999046325684	-0.17300009727478027	-4.910590325890383	yfinance
1952	2026-01-07	CM.NATGAS	3.5250000953674316	0.17500019073486328	5.223886439305958	yfinance
1953	2026-01-08	CM.NATGAS	3.4070000648498535	-0.11800003051757812	-3.3475185056776087	yfinance
1954	2026-01-09	CM.NATGAS	3.1689999103546143	-0.23800015449523926	-6.985622247287158	yfinance
1955	2026-01-12	CM.NATGAS	3.4089999198913574	0.24000000953674316	7.573367507917882	yfinance
1956	2026-01-13	CM.NATGAS	3.4189999103546143	0.009999990463256836	0.2933408829054924	yfinance
1957	2026-01-14	CM.NATGAS	3.119999885559082	-0.2990000247955322	-8.745248102814964	yfinance
1958	2026-01-15	CM.NATGAS	3.128000020980835	0.00800013542175293	0.25641460625628715	yfinance
1959	2026-01-16	CM.NATGAS	3.1029999256134033	-0.02500009536743164	-0.7992357800430083	yfinance
1960	2026-01-20	CM.NATGAS	3.9070000648498535	0.8040001392364502	25.91041438963344	yfinance
1961	2026-01-21	CM.NATGAS	4.875	0.9679999351501465	24.776040928664454	yfinance
1962	2026-01-22	CM.NATGAS	5.045000076293945	0.1700000762939453	3.4871810521834936	yfinance
1963	2026-01-23	CM.NATGAS	5.275000095367432	0.23000001907348633	4.558969585634659	yfinance
1964	2026-01-26	CM.NATGAS	6.800000190734863	1.5250000953674316	28.90995389188154	yfinance
1965	2026-01-27	CM.NATGAS	6.953999996185303	0.15399980545043945	2.2647029578067848	yfinance
1966	2026-01-28	CM.NATGAS	7.460000038146973	0.5060000419616699	7.276388297947111	yfinance
1967	2026-01-29	CM.NATGAS	3.9179999828338623	-3.5420000553131104	-47.4798932600666	yfinance
1968	2026-01-30	CM.NATGAS	4.354000091552734	0.43600010871887207	11.128129418814245	yfinance
1969	2026-02-02	CM.NATGAS	3.236999988555908	-1.1170001029968262	-25.654572335998246	yfinance
1970	2026-02-03	CM.NATGAS	3.311000108718872	0.07400012016296387	2.286071066561135	yfinance
1971	2026-02-04	CM.NATGAS	3.4649999141693115	0.15399980545043945	4.651156762118824	yfinance
1972	2026-02-05	CM.NATGAS	3.509000062942505	0.04400014877319336	1.269845594894966	yfinance
1973	2026-02-06	CM.NATGAS	3.421999931335449	-0.08700013160705566	-2.479342549059429	yfinance
1974	2025-12-09	FX.EURUSD	1.1641442775726318	\N	\N	yfinance
1975	2025-12-10	FX.EURUSD	1.1628313064575195	-0.0013129711151123047	-0.11278422618285708	yfinance
1976	2025-12-11	FX.EURUSD	1.1701242923736572	0.007292985916137695	0.627174885612191	yfinance
1977	2025-12-12	FX.EURUSD	1.1739431619644165	0.0038188695907592773	0.32636443971370804	yfinance
1978	2025-12-15	FX.EURUSD	1.1737639904022217	-0.00017917156219482422	-0.015262371126640209	yfinance
1979	2025-12-16	FX.EURUSD	1.1754610538482666	0.0016970634460449219	0.1445830217932804	yfinance
1980	2025-12-17	FX.EURUSD	1.1749500036239624	-0.0005110502243041992	-0.04347657650001288	yfinance
1981	2025-12-18	FX.EURUSD	1.1742326021194458	-0.0007174015045166016	-0.0610580452192758	yfinance
1982	2025-12-19	FX.EURUSD	1.1725666522979736	-0.001665949821472168	-0.14187562314870078	yfinance
1983	2025-12-22	FX.EURUSD	1.1708093881607056	-0.0017572641372680664	-0.1498647547091855	yfinance
1984	2025-12-23	FX.EURUSD	1.1765950918197632	0.005785703659057617	0.49416273200087035	yfinance
1985	2025-12-24	FX.EURUSD	1.179551362991333	0.0029562711715698242	0.2512564596030697	yfinance
1986	2025-12-26	FX.EURUSD	1.1785364151000977	-0.0010149478912353516	-0.08604524763223974	yfinance
1987	2025-12-29	FX.EURUSD	1.1772738695144653	-0.0012625455856323242	-0.1071282626023135	yfinance
1988	2025-12-30	FX.EURUSD	1.1772878170013428	1.3947486877441406e-05	0.0011847274655975902	yfinance
1989	2025-12-31	FX.EURUSD	1.1747292280197144	-0.002558588981628418	-0.21732909698712186	yfinance
1990	2026-01-02	FX.EURUSD	1.175046682357788	0.00031745433807373047	0.027023617911412258	yfinance
1991	2026-01-05	FX.EURUSD	1.1704667806625366	-0.004579901695251465	-0.3897633825118905	yfinance
1992	2026-01-06	FX.EURUSD	1.1714951992034912	0.0010284185409545898	0.08786396657686081	yfinance
1993	2026-01-07	FX.EURUSD	1.1688251495361328	-0.0026700496673583984	-0.2279181057825748	yfinance
1994	2026-01-08	FX.EURUSD	1.1676785945892334	-0.001146554946899414	-0.09809465062883382	yfinance
1995	2026-01-09	FX.EURUSD	1.1657865047454834	-0.00189208984375	-0.16203858257893305	yfinance
1996	2026-01-12	FX.EURUSD	1.1623716354370117	-0.0034148693084716797	-0.29292407268149157	yfinance
1997	2026-01-13	FX.EURUSD	1.1666978597640991	0.004326224327087402	0.37218942678869577	yfinance
1998	2026-01-14	FX.EURUSD	1.164252758026123	-0.0024451017379760742	-0.20957454558718933	yfinance
1999	2026-01-15	FX.EURUSD	1.1646324396133423	0.0003796815872192383	0.03261161157676374	yfinance
2000	2026-01-16	FX.EURUSD	1.1609008312225342	-0.0037316083908081055	-0.32041082352531747	yfinance
2001	2026-01-19	FX.EURUSD	1.162493348121643	0.0015925168991088867	0.13717940897947514	yfinance
2002	2026-01-20	FX.EURUSD	1.1639139652252197	0.0014206171035766602	0.1222043210717802	yfinance
2003	2026-01-21	FX.EURUSD	1.1727865934371948	0.008872628211975098	0.7623096274352397	yfinance
2004	2026-01-22	FX.EURUSD	1.1672970056533813	-0.0054895877838134766	-0.4680807074818813	yfinance
2005	2026-01-23	FX.EURUSD	1.1754610538482666	0.008164048194885254	0.6993976815965119	yfinance
2006	2026-01-26	FX.EURUSD	1.1858457326889038	0.010384678840637207	0.8834557986110618	yfinance
2007	2026-01-27	FX.EURUSD	1.1876484155654907	0.001802682876586914	0.15201664321878805	yfinance
2008	2026-01-28	FX.EURUSD	1.2017642259597778	0.01411581039428711	1.1885512757212717	yfinance
2009	2026-01-29	FX.EURUSD	1.1977769136428833	-0.003987312316894531	-0.33178823522643147	yfinance
2010	2026-01-30	FX.EURUSD	1.19657301902771	-0.0012038946151733398	-0.10051075467065484	yfinance
2011	2026-02-02	FX.EURUSD	1.1849182844161987	-0.01165473461151123	-0.9740094775813538	yfinance
2012	2026-02-03	FX.EURUSD	1.1798714399337769	-0.005046844482421875	-0.4259234201038953	yfinance
2013	2026-02-04	FX.EURUSD	1.1816140413284302	0.0017426013946533203	0.14769417545619445	yfinance
2014	2026-02-05	FX.EURUSD	1.180163860321045	-0.001450181007385254	-0.12272882317434948	yfinance
2015	2026-02-06	FX.EURUSD	1.177786946296692	-0.0023769140243530273	-0.20140542379483012	yfinance
2016	2025-12-09	FX.GBPUSD	1.3326793909072876	\N	\N	yfinance
2017	2025-12-10	FX.GBPUSD	1.3303532600402832	-0.0023261308670043945	-0.17454542201787676	yfinance
2018	2025-12-11	FX.GBPUSD	1.3388315439224243	0.008478283882141113	0.6372956820419555	yfinance
2019	2025-12-12	FX.GBPUSD	1.339046597480774	0.00021505355834960938	0.0160627794680994	yfinance
2020	2025-12-15	FX.GBPUSD	1.3367732763290405	-0.0022733211517333984	-0.16977162378145239	yfinance
2021	2025-12-16	FX.GBPUSD	1.3380612134933472	0.0012879371643066406	0.09634671691249615	yfinance
2022	2025-12-17	FX.GBPUSD	1.342499852180481	0.004438638687133789	0.331721646392066	yfinance
2023	2025-12-18	FX.GBPUSD	1.3374598026275635	-0.0050400495529174805	-0.3754227268428715	yfinance
2024	2025-12-19	FX.GBPUSD	1.3385393619537354	0.001079559326171875	0.08071714185734635	yfinance
2025	2025-12-22	FX.GBPUSD	1.3377031087875366	-0.0008362531661987305	-0.06247505228222301	yfinance
2026	2025-12-23	FX.GBPUSD	1.3469899892807007	0.009286880493164062	0.6942407797483163	yfinance
2027	2025-12-24	FX.GBPUSD	1.3513604402542114	0.004370450973510742	0.3244605385556417	yfinance
2028	2025-12-26	FX.GBPUSD	1.3508949279785156	-0.0004655122756958008	-0.03444767671371458	yfinance
2029	2025-12-29	FX.GBPUSD	1.349727988243103	-0.0011669397354125977	-0.08638271646772787	yfinance
2030	2025-12-30	FX.GBPUSD	1.3510993719100952	0.0013713836669921875	0.10160444763224277	yfinance
2031	2025-12-31	FX.GBPUSD	1.346719741821289	-0.004379630088806152	-0.3241530697046006	yfinance
2032	2026-01-02	FX.GBPUSD	1.347363829612732	0.0006440877914428711	0.047826416398397326	yfinance
2033	2026-01-05	FX.GBPUSD	1.3437970876693726	-0.003566741943359375	-0.26472003069761424	yfinance
2034	2026-01-06	FX.GBPUSD	1.3533997535705566	0.009602665901184082	0.7145919565757177	yfinance
2035	2026-01-07	FX.GBPUSD	1.3500559329986572	-0.003343820571899414	-0.2470682119660288	yfinance
2036	2026-01-08	FX.GBPUSD	1.3459312915802002	-0.004124641418457031	-0.30551633585251864	yfinance
2037	2026-01-09	FX.GBPUSD	1.3438005447387695	-0.002130746841430664	-0.15831022391410823	yfinance
2038	2026-01-12	FX.GBPUSD	1.3394231796264648	-0.0043773651123046875	-0.3257451509037476	yfinance
2039	2026-01-13	FX.GBPUSD	1.3465656042099	0.007142424583435059	0.5332463027425672	yfinance
2040	2026-01-14	FX.GBPUSD	1.3426783084869385	-0.0038872957229614258	-0.28868223804382	yfinance
2041	2026-01-15	FX.GBPUSD	1.344266653060913	0.0015883445739746094	0.11829673302494265	yfinance
2042	2026-01-16	FX.GBPUSD	1.3381328582763672	-0.0061337947845458984	-0.4562930108084706	yfinance
2043	2026-01-19	FX.GBPUSD	1.3404287099838257	0.002295851707458496	0.1715712825717287	yfinance
2044	2026-01-20	FX.GBPUSD	1.3418315649032593	0.0014028549194335938	0.10465718236149399	yfinance
2045	2026-01-21	FX.GBPUSD	1.344085931777954	0.0022543668746948242	0.1680066957477897	yfinance
2046	2026-01-22	FX.GBPUSD	1.3419395685195923	-0.0021463632583618164	-0.15968943708253916	yfinance
2047	2026-01-23	FX.GBPUSD	1.3501288890838623	0.00818932056427002	0.6102600114328811	yfinance
2048	2026-01-26	FX.GBPUSD	1.3662508726119995	0.016121983528137207	1.194106996634734	yfinance
2049	2026-01-27	FX.GBPUSD	1.3677457571029663	0.0014948844909667969	0.10941508041703026	yfinance
2050	2026-01-28	FX.GBPUSD	1.3824374675750732	0.014691710472106934	1.074155075664469	yfinance
2051	2026-01-29	FX.GBPUSD	1.382533073425293	9.560585021972656e-05	0.006915745012859664	yfinance
2052	2026-01-30	FX.GBPUSD	1.380643367767334	-0.0018897056579589844	-0.13668430030951423	yfinance
2053	2026-02-02	FX.GBPUSD	1.3679141998291016	-0.012729167938232422	-0.9219736418114269	yfinance
2054	2026-02-03	FX.GBPUSD	1.367315649986267	-0.0005985498428344727	-0.04375638785745858	yfinance
2055	2026-02-04	FX.GBPUSD	1.3697504997253418	0.002434849739074707	0.1780751751871751	yfinance
2056	2026-02-05	FX.GBPUSD	1.3644611835479736	-0.005289316177368164	-0.38615179760319573	yfinance
2057	2026-02-06	FX.GBPUSD	1.3520822525024414	-0.012378931045532227	-0.9072395165792557	yfinance
2058	2025-12-09	FX.USDJPY	155.843994140625	\N	\N	yfinance
2059	2025-12-10	FX.USDJPY	156.83799743652344	0.9940032958984375	0.6378194433347902	yfinance
2060	2025-12-11	FX.USDJPY	155.7899932861328	-1.048004150390625	-0.6682080666164973	yfinance
2061	2025-12-12	FX.USDJPY	155.56700134277344	-0.222991943359375	-0.14313624299977679	yfinance
2062	2025-12-15	FX.USDJPY	155.88800048828125	0.3209991455078125	0.20634141092719846	yfinance
2063	2025-12-16	FX.USDJPY	155.01499938964844	-0.8730010986328125	-0.560018151428172	yfinance
2064	2025-12-17	FX.USDJPY	154.7779998779297	-0.23699951171875	-0.1528881157642196	yfinance
2065	2025-12-18	FX.USDJPY	155.4949951171875	0.7169952392578125	0.46324105481611877	yfinance
2066	2025-12-19	FX.USDJPY	155.58599853515625	0.09100341796875	0.05852498204213328	yfinance
2067	2025-12-22	FX.USDJPY	157.67599487304688	2.089996337890625	1.3433061827979136	yfinance
2068	2025-12-23	FX.USDJPY	156.8769989013672	-0.7989959716796875	-0.5067327923461022	yfinance
2069	2025-12-24	FX.USDJPY	156.17599487304688	-0.7010040283203125	-0.4468494637388192	yfinance
2070	2025-12-26	FX.USDJPY	156.08999633789062	-0.08599853515625	-0.055065143158624937	yfinance
2071	2025-12-29	FX.USDJPY	156.46299743652344	0.3730010986328125	0.23896540930487997	yfinance
2072	2025-12-30	FX.USDJPY	156.01300048828125	-0.4499969482421875	-0.28760598711190477	yfinance
2073	2025-12-31	FX.USDJPY	156.41299438476562	0.399993896484375	0.25638497768294644	yfinance
2074	2026-01-02	FX.USDJPY	156.7310028076172	0.3180084228515625	0.2033133014954517	yfinance
2075	2026-01-05	FX.USDJPY	156.98899841308594	0.25799560546875	0.16461044773983372	yfinance
2076	2026-01-06	FX.USDJPY	156.62600708007812	-0.3629913330078125	-0.23122087323130222	yfinance
2077	2026-01-07	FX.USDJPY	156.67999267578125	0.053985595703125	0.03446783628693529	yfinance
2078	2026-01-08	FX.USDJPY	156.7310028076172	0.0510101318359375	0.032556889341636	yfinance
2079	2026-01-09	FX.USDJPY	156.8800048828125	0.1490020751953125	0.09506866703214314	yfinance
2080	2026-01-12	FX.USDJPY	158.1490020751953	1.2689971923828125	0.8088967063270672	yfinance
2081	2026-01-13	FX.USDJPY	157.98599243164062	-0.1630096435546875	-0.1030734569397922	yfinance
2082	2026-01-14	FX.USDJPY	159.1790008544922	1.1930084228515625	0.7551355689763246	yfinance
2083	2026-01-15	FX.USDJPY	158.40199279785156	-0.777008056640625	-0.4881347743543756	yfinance
2084	2026-01-16	FX.USDJPY	158.5959930419922	0.194000244140625	0.12247336079174394	yfinance
2085	2026-01-19	FX.USDJPY	157.53500366210938	-1.0609893798828125	-0.6689887679582733	yfinance
2086	2026-01-20	FX.USDJPY	158.177001953125	0.641998291015625	0.40752739143144456	yfinance
2087	2026-01-21	FX.USDJPY	158.16200256347656	-0.0149993896484375	-0.009482661488856957	yfinance
2088	2026-01-22	FX.USDJPY	158.45599365234375	0.2939910888671875	0.18587972085722515	yfinance
2089	2026-01-23	FX.USDJPY	158.50100708007812	0.045013427734375	0.028407526087738617	yfinance
2090	2026-01-26	FX.USDJPY	155.16600036621094	-3.3350067138671875	-2.104091813235149	yfinance
2091	2026-01-27	FX.USDJPY	154.33599853515625	-0.8300018310546875	-0.5349121773428333	yfinance
2092	2026-01-28	FX.USDJPY	152.4530029296875	-1.88299560546875	-1.2200624762471224	yfinance
2093	2026-01-29	FX.USDJPY	153.0959930419922	0.6429901123046875	0.4217628383491006	yfinance
2094	2026-01-30	FX.USDJPY	153.16200256347656	0.066009521484375	0.043116426611027936	yfinance
2095	2026-02-02	FX.USDJPY	155.20199584960938	2.0399932861328125	1.331918656056587	yfinance
2096	2026-02-03	FX.USDJPY	155.4429931640625	0.240997314453125	0.1552797779009564	yfinance
2097	2026-02-04	FX.USDJPY	155.7989959716797	0.3560028076171875	0.22902467352867034	yfinance
2098	2026-02-05	FX.USDJPY	156.91700744628906	1.118011474609375	0.7175986389620901	yfinance
2099	2026-02-06	FX.USDJPY	156.78399658203125	-0.1330108642578125	-0.08476510381026775	yfinance
2100	2025-12-09	FX.DXY	99.22000122070312	\N	\N	yfinance
2101	2025-12-10	FX.DXY	98.79000091552734	-0.43000030517578125	-0.433380669104505	yfinance
2102	2025-12-11	FX.DXY	98.3499984741211	-0.44000244140625	-0.44539167661561635	yfinance
2103	2025-12-12	FX.DXY	98.4000015258789	0.0500030517578125	0.05084194461982614	yfinance
2104	2025-12-15	FX.DXY	98.1500015258789	-0.25	-0.2540650367106455	yfinance
2105	2025-12-16	FX.DXY	98.1500015258789	0	0	yfinance
2106	2025-12-17	FX.DXY	98.37000274658203	0.220001220703125	0.22414795444003938	yfinance
2107	2025-12-18	FX.DXY	98.43000030517578	0.05999755859375	0.060991721986949604	yfinance
2108	2025-12-19	FX.DXY	98.5999984741211	0.1699981689453125	0.1727097108790453	yfinance
2109	2025-12-22	FX.DXY	98.29000091552734	-0.30999755859375	-0.31439915151227216	yfinance
2110	2025-12-23	FX.DXY	97.94000244140625	-0.34999847412109375	-0.3560875682785784	yfinance
2111	2025-12-24	FX.DXY	97.9800033569336	0.04000091552734375	0.040842265193198016	yfinance
2112	2025-12-26	FX.DXY	98.0199966430664	0.0399932861328125	0.040817804411702296	yfinance
2113	2025-12-29	FX.DXY	98.04000091552734	0.0200042724609375	0.02040835864724806	yfinance
2114	2025-12-30	FX.DXY	98.23999786376953	0.1999969482421875	0.20399525334001956	yfinance
2115	2025-12-31	FX.DXY	98.27999877929688	0.04000091552734375	0.040717545192553294	yfinance
2116	2026-01-02	FX.DXY	98.41999816894531	0.1399993896484375	0.14244952318612464	yfinance
2117	2026-01-05	FX.DXY	98.2699966430664	-0.15000152587890625	-0.15240960035522189	yfinance
2118	2026-01-06	FX.DXY	98.58000183105469	0.31000518798828125	0.3154627033460412	yfinance
2119	2026-01-07	FX.DXY	98.68000030517578	0.09999847412109375	0.1014389047105822	yfinance
2120	2026-01-08	FX.DXY	98.93000030517578	0.25	0.25334414189993415	yfinance
2121	2026-01-09	FX.DXY	99.12999725341797	0.1999969482421875	0.2021600602701344	yfinance
2122	2026-01-12	FX.DXY	98.86000061035156	-0.26999664306640625	-0.2723662368073927	yfinance
2123	2026-01-13	FX.DXY	99.12999725341797	0.26999664306640625	0.2731100964995696	yfinance
2124	2026-01-14	FX.DXY	99.12999725341797	0	0	yfinance
2125	2026-01-15	FX.DXY	99.31999969482422	0.19000244140625	0.19166997545709988	yfinance
2126	2026-01-16	FX.DXY	99.38999938964844	0.06999969482421875	0.07047895191230713	yfinance
2127	2026-01-20	FX.DXY	98.63999938964844	-0.75	-0.7546030834145605	yfinance
2128	2026-01-21	FX.DXY	98.76000213623047	0.12000274658203125	0.12165728641987875	yfinance
2129	2026-01-22	FX.DXY	98.36000061035156	-0.40000152587890625	-0.40502381250168507	yfinance
2130	2026-01-23	FX.DXY	97.5999984741211	-0.7600021362304688	-0.7726739848662475	yfinance
2131	2026-01-26	FX.DXY	97.04000091552734	-0.55999755859375	-0.5737679993327407	yfinance
2132	2026-01-27	FX.DXY	96.22000122070312	-0.8199996948242188	-0.8450120435778055	yfinance
2133	2026-01-28	FX.DXY	96.44999694824219	0.2299957275390625	0.23903110020910662	yfinance
2134	2026-01-29	FX.DXY	96.27999877929688	-0.1699981689453125	-0.1762552351728309	yfinance
2135	2026-01-30	FX.DXY	96.98999786376953	0.7099990844726562	0.7374315470237912	yfinance
2136	2026-02-02	FX.DXY	97.61000061035156	0.6200027465820312	0.6392440047816852	yfinance
2137	2026-02-03	FX.DXY	97.44000244140625	-0.1699981689453125	-0.17416060637467526	yfinance
2138	2026-02-04	FX.DXY	97.62000274658203	0.18000030517578125	0.184729372604461	yfinance
2139	2026-02-05	FX.DXY	97.81999969482422	0.1999969482421875	0.20487291806513497	yfinance
2140	2026-02-06	FX.DXY	97.62999725341797	-0.19000244140625	-0.19423680433348361	yfinance
2141	2025-12-09	EQ.XLE	45.3137321472168	\N	\N	yfinance
2142	2025-12-10	EQ.XLE	45.7896728515625	0.4759407043457031	1.0503233386282347	yfinance
2143	2025-12-11	EQ.XLE	45.571533203125	-0.2181396484375	-0.47639486122700336	yfinance
2144	2025-12-12	EQ.XLE	45.125335693359375	-0.446197509765625	-0.9791145445486737	yfinance
2145	2025-12-15	EQ.XLE	44.808040618896484	-0.3172950744628906	-0.703141748615476	yfinance
2146	2025-12-16	EQ.XLE	43.43970489501953	-1.3683357238769531	-3.0537727268973627	yfinance
2147	2025-12-17	EQ.XLE	44.40150451660156	0.9617996215820312	2.2141025679304374	yfinance
2148	2025-12-18	EQ.XLE	43.75699996948242	-0.6445045471191406	-1.4515376317443538	yfinance
2149	2025-12-19	EQ.XLE	43.75699996948242	0	0	yfinance
2150	2025-12-22	EQ.XLE	44.209999084472656	0.4529991149902344	1.0352609075260437	yfinance
2151	2025-12-23	EQ.XLE	44.5	0.29000091552734375	0.6559622744466359	yfinance
2152	2025-12-24	EQ.XLE	44.369998931884766	-0.13000106811523438	-0.2921372317196278	yfinance
2153	2025-12-26	EQ.XLE	44.20000076293945	-0.1699981689453125	-0.38313764488993474	yfinance
2154	2025-12-29	EQ.XLE	44.619998931884766	0.4199981689453125	0.950222085284374	yfinance
2155	2025-12-30	EQ.XLE	44.959999084472656	0.3400001525878906	0.7619904991636648	yfinance
2156	2025-12-31	EQ.XLE	44.709999084472656	-0.25	-0.5560498333869845	yfinance
2157	2026-01-02	EQ.XLE	45.650001525878906	0.94000244140625	2.102443436937362	yfinance
2158	2026-01-05	EQ.XLE	46.88999938964844	1.2399978637695312	2.7163150543742667	yfinance
2159	2026-01-06	EQ.XLE	45.63999938964844	-1.25	-2.6658136410126576	yfinance
2160	2026-01-07	EQ.XLE	45.130001068115234	-0.5099983215332031	-1.1174371786886468	yfinance
2161	2026-01-08	EQ.XLE	46.54999923706055	1.4199981689453125	3.146461633807836	yfinance
2162	2026-01-09	EQ.XLE	46.66999816894531	0.11999893188476562	0.25778503512676554	yfinance
2163	2026-01-12	EQ.XLE	46.34000015258789	-0.3299980163574219	-0.707088127929274	yfinance
5489	2024-09-25	EQ.LVMH	597.4401	3.28961181640625	0.5536664104661309	yfinance_direct
5490	2024-09-26	EQ.LVMH	656.4584	59.018310546875	9.878531441976719	yfinance_direct
5491	2024-09-27	EQ.LVMH	680.5496	24.09112548828125	3.6698630410820967	yfinance_direct
5492	2024-09-30	EQ.LVMH	666.1335	-14.416015625	-2.1182903436768954	yfinance_direct
5493	2024-10-01	EQ.LVMH	642.4295	-23.70404052734375	-3.5584517110790137	yfinance_direct
5494	2024-10-02	EQ.LVMH	646.6866	4.257080078125	0.6626532637440365	yfinance_direct
5495	2024-10-03	EQ.LVMH	639.527	-7.15960693359375	-1.1071216112256428	yfinance_direct
5496	2024-10-04	EQ.LVMH	640.3978	0.87078857421875	0.136161351248949	yfinance_direct
5497	2024-10-07	EQ.LVMH	657.7162	17.3184814453125	2.7043319576865916	yfinance_direct
5498	2024-10-08	EQ.LVMH	634.2056	-23.5106201171875	-3.574584055731878	yfinance_direct
5499	2024-10-09	EQ.LVMH	635.0764	0.87078857421875	0.13730382332490443	yfinance_direct
5500	2024-10-10	EQ.LVMH	633.7219	-1.35455322265625	-0.21328980080137686	yfinance_direct
5501	2024-10-11	EQ.LVMH	631.8836	-1.8382568359375	-0.29007312890166803	yfinance_direct
5502	2024-10-14	EQ.LVMH	617.0806	-14.802978515625	-2.3426748812710323	yfinance_direct
5503	2024-10-15	EQ.LVMH	605.0834	-11.9971923828125	-1.9441855487436561	yfinance_direct
5504	2024-10-16	EQ.LVMH	582.8306	-22.2528076171875	-3.6776428386330937	yfinance_direct
5505	2024-10-17	EQ.LVMH	589.6033	6.77264404296875	1.1620261057144985	yfinance_direct
5506	2024-10-18	EQ.LVMH	602.955	13.3516845703125	2.264520096148471	yfinance_direct
5507	2024-10-21	EQ.LVMH	591.1512	-11.8037109375	-1.9576439034078383	yfinance_direct
5508	2024-10-22	EQ.LVMH	595.9888	4.83758544921875	0.8183329544133441	yfinance_direct
5509	2024-10-23	EQ.LVMH	593.6667	-2.32208251953125	-0.3896184627024682	yfinance_direct
5510	2024-10-24	EQ.LVMH	608.2762	14.6094970703125	2.4608919260471964	yfinance_direct
5511	2024-10-25	EQ.LVMH	606.6315	-1.644775390625	-0.2703994120809577	yfinance_direct
5512	2024-10-28	EQ.LVMH	611.5658	4.934326171875	0.8133976587299591	yfinance_direct
5513	2024-10-29	EQ.LVMH	610.4048	-1.1610107421875	-0.18984232767332668	yfinance_direct
5514	2024-10-30	EQ.LVMH	598.0205	-12.38427734375	-2.02886308313915	yfinance_direct
5515	2024-10-31	EQ.LVMH	589.9902	-8.0302734375	-1.3428090395886167	yfinance_direct
2164	2026-01-13	EQ.XLE	47	0.6599998474121094	1.424255168836574	yfinance
2165	2026-01-14	EQ.XLE	48.060001373291016	1.0600013732910156	2.2553220708319484	yfinance
2166	2026-01-15	EQ.XLE	47.61000061035156	-0.4500007629394531	-0.9363311487326291	yfinance
2167	2026-01-16	EQ.XLE	47.689998626708984	0.07999801635742188	0.1680277574708293	yfinance
5516	2024-11-01	EQ.LVMH	591.1512	1.1610107421875	0.19678473888934866	yfinance_direct
5517	2024-11-04	EQ.LVMH	586.991	-4.1602783203125	-0.7037587004469191	yfinance_direct
5518	2024-11-05	EQ.LVMH	583.0241	-3.96685791015625	-0.6757953928665753	yfinance_direct
5519	2024-11-06	EQ.LVMH	583.5079	0.4837646484375	0.08297506759390205	yfinance_direct
5520	2024-11-07	EQ.LVMH	598.8914	15.38348388671875	2.6363798304071895	yfinance_direct
5521	2024-11-08	EQ.LVMH	578.9606	-19.93072509765625	-3.3279366700923214	yfinance_direct
5522	2024-11-11	EQ.LVMH	580.0248	1.064208984375	0.18381370424147275	yfinance_direct
5523	2024-11-12	EQ.LVMH	553.8052	-26.21966552734375	-4.5204383778097466	yfinance_direct
5524	2024-11-13	EQ.LVMH	555.3532	1.54803466796875	0.27952694118196814	yfinance_direct
5525	2024-11-14	EQ.LVMH	565.4154	10.06219482421875	1.8118549843404268	yfinance_direct
5526	2024-11-15	EQ.LVMH	567.2537	1.8382568359375	0.3251161568632023	yfinance_direct
5527	2024-11-18	EQ.LVMH	569.4789	2.2252197265625	0.39227948186140477	yfinance_direct
5528	2024-11-19	EQ.LVMH	558.546	-10.932861328125	-1.9198010105095826	yfinance_direct
5529	2024-11-20	EQ.LVMH	556.7078	-1.83819580078125	-0.32910373242119245	yfinance_direct
5530	2024-11-21	EQ.LVMH	556.224	-0.48382568359375	-0.0869083677507792	yfinance_direct
5531	2024-11-22	EQ.LVMH	564.0609	7.83685302734375	1.4089383128205386	yfinance_direct
5532	2024-11-25	EQ.LVMH	573.2522	9.19134521484375	1.6294953250923843	yfinance_direct
5533	2024-11-26	EQ.LVMH	576.6385	3.3863525390625	0.5907264822036753	yfinance_direct
5534	2024-11-27	EQ.LVMH	570.9302	-5.7083740234375	-0.9899397162002048	yfinance_direct
5535	2024-11-28	EQ.LVMH	567.4471	-3.4830322265625	-0.610062731716078	yfinance_direct
5536	2024-11-29	EQ.LVMH	573.2522	5.8050537109375	1.0230122359190341	yfinance_direct
5537	2024-12-02	EQ.LVMH	591.9048	18.65264892578125	3.2538294689062073	yfinance_direct
5538	2024-12-03	EQ.LVMH	594.9323	3.0274658203125	0.5114784647891696	yfinance_direct
5539	2024-12-04	EQ.LVMH	595.9089	0.9765625	0.16414682482076448	yfinance_direct
5540	2024-12-05	EQ.LVMH	594.9323	-0.9765625	-0.16387782457513905	yfinance_direct
5541	2024-12-06	EQ.LVMH	615.6358	20.7034912109375	3.479974241259515	yfinance_direct
5542	2024-12-09	EQ.LVMH	637.3159	21.6800537109375	3.521571292223318	yfinance_direct
5543	2024-12-10	EQ.LVMH	621.1046	-16.21124267578125	-2.5436747727854523	yfinance_direct
5544	2024-12-11	EQ.LVMH	628.7219	7.6173095703125	1.2264132958366099	yfinance_direct
5545	2024-12-12	EQ.LVMH	630.8704	2.14849853515625	0.34172476793470136	yfinance_direct
5546	2024-12-13	EQ.LVMH	624.0344	-6.8360595703125	-1.0835917056793027	yfinance_direct
5547	2024-12-16	EQ.LVMH	616.4171	-7.6173095703125	-1.2206554677886605	yfinance_direct
5548	2024-12-17	EQ.LVMH	620.714	4.29693603515625	0.6970826022238797	yfinance_direct
5549	2024-12-18	EQ.LVMH	621.593	0.87896728515625	0.1416058442966995	yfinance_direct
5550	2024-12-19	EQ.LVMH	612.8037	-8.78924560546875	-1.4139873228858213	yfinance_direct
5551	2024-12-20	EQ.LVMH	613.3896	0.5859375	0.0956158537459901	yfinance_direct
5552	2024-12-23	EQ.LVMH	614.4639	1.07427978515625	0.17513823193671182	yfinance_direct
5553	2024-12-24	EQ.LVMH	616.0264	1.5625	0.25428669255159514	yfinance_direct
5554	2024-12-27	EQ.LVMH	620.714	4.68756103515625	0.7609350541470569	yfinance_direct
5555	2024-12-30	EQ.LVMH	614.5615	-6.1524658203125	-0.9911917447952158	yfinance_direct
5556	2024-12-31	EQ.LVMH	620.6163	6.0548095703125	0.9852243167527661	yfinance_direct
5557	2025-01-02	EQ.LVMH	620.5187	-0.09765625	-0.01573536576562684	yfinance_direct
5558	2025-01-03	EQ.LVMH	596.9831	-23.53558349609375	-3.79288881666968	yfinance_direct
5559	2025-01-06	EQ.LVMH	619.7374	22.7542724609375	3.811543864101018	yfinance_direct
5560	2025-01-07	EQ.LVMH	629.4056	9.668212890625	1.560050018825507	yfinance_direct
5561	2025-01-08	EQ.LVMH	620.8116	-8.59393310546875	-1.3654046607599304	yfinance_direct
5562	2025-01-09	EQ.LVMH	632.8236	12.011962890625	1.9348804065683136	yfinance_direct
5563	2025-01-10	EQ.LVMH	629.8939	-2.92974853515625	-0.4629644811404738	yfinance_direct
5564	2025-01-13	EQ.LVMH	631.2611	1.36724853515625	0.21706014652262398	yfinance_direct
5565	2025-01-14	EQ.LVMH	635.7534	4.49224853515625	0.7116308094052336	yfinance_direct
5566	2025-01-15	EQ.LVMH	622.2766	-13.476806640625	-2.119816827334927	yfinance_direct
5567	2025-01-16	EQ.LVMH	679.2111	56.9345703125	9.149399938933119	yfinance_direct
5568	2025-01-17	EQ.LVMH	673.9376	-5.2735595703125	-0.7764242089575174	yfinance_direct
5569	2025-01-20	EQ.LVMH	667.1015	-6.8360595703125	-1.0143461301982386	yfinance_direct
5570	2025-01-21	EQ.LVMH	684.8752	17.77374267578125	2.6643235904510894	yfinance_direct
5571	2025-01-22	EQ.LVMH	697.0825	12.207275390625	1.7824086204112362	yfinance_direct
5572	2025-01-23	EQ.LVMH	703.7232	6.64068603515625	0.9526398739164696	yfinance_direct
5573	2025-01-24	EQ.LVMH	716.9071	13.18389892578125	1.8734495070643458	yfinance_direct
5574	2025-01-27	EQ.LVMH	737.1223	20.21514892578125	2.819772436221065	yfinance_direct
5575	2025-01-28	EQ.LVMH	733.0206	-4.10162353515625	-0.556437350268208	yfinance_direct
5576	2025-01-29	EQ.LVMH	696.4966	-36.5240478515625	-4.982676661828955	yfinance_direct
5577	2025-01-30	EQ.LVMH	699.0356	2.5390625	0.3645477329687856	yfinance_direct
5578	2025-01-31	EQ.LVMH	687.0237	-12.01190185546875	-1.7183532698856194	yfinance_direct
5579	2025-02-03	EQ.LVMH	673.9376	-13.086181640625	-1.9047641046083326	yfinance_direct
5580	2025-02-04	EQ.LVMH	676.4767	2.53912353515625	0.3767594628879567	yfinance_direct
5581	2025-02-05	EQ.LVMH	669.9337	-6.54302978515625	-0.9672217734026238	yfinance_direct
5582	2025-02-06	EQ.LVMH	680.5784	10.64471435546875	1.5889206758663956	yfinance_direct
5583	2025-02-07	EQ.LVMH	668.1758	-12.402587890625	-1.822359988649934	yfinance_direct
5584	2025-02-10	EQ.LVMH	669.25	1.07421875	0.16076888449778723	yfinance_direct
5585	2025-02-11	EQ.LVMH	669.1524	-0.09759521484375	-0.014582773977400074	yfinance_direct
5586	2025-02-12	EQ.LVMH	671.6915	2.5390625	0.379444575233233	yfinance_direct
5587	2025-02-13	EQ.LVMH	690.6371	18.94561767578125	2.8205833479403393	yfinance_direct
5588	2025-02-14	EQ.LVMH	696.3013	5.6641845703125	0.8201390706716635	yfinance_direct
5589	2025-02-17	EQ.LVMH	685.0706	-11.230712890625	-1.612910012096562	yfinance_direct
5590	2025-02-18	EQ.LVMH	688.5863	3.5157470703125	0.5131948871883563	yfinance_direct
5591	2025-02-19	EQ.LVMH	674.7189	-13.86737060546875	-2.013889984557426	yfinance_direct
5592	2025-02-20	EQ.LVMH	679.2111	4.4921875	0.6657864896904861	yfinance_direct
863	2026-02-09	EQ.SPX	6964.81982421875	\N	\N	yfinance
864	2026-02-10	EQ.SPX	6941.81005859375	-23.009765625	-0.33037129754582023	yfinance
865	2026-02-11	EQ.SPX	6941.47021484375	-0.33984375	-0.004895607156224099	yfinance
866	2026-02-12	EQ.SPX	6832.759765625	-108.71044921875	-1.5661012127701974	yfinance
867	2026-02-13	EQ.SPX	6836.169921875	3.41015625	0.0499089148012519	yfinance
868	2026-02-17	EQ.SPX	6843.22021484375	7.05029296875	0.10313220779064941	yfinance
869	2026-02-18	EQ.SPX	6881.31005859375	38.08984375	0.5566070147410812	yfinance
870	2026-02-19	EQ.SPX	6861.89013671875	-19.419921875	-0.2822125686772006	yfinance
871	2026-02-20	EQ.SPX	6909.509765625	47.61962890625	0.6939724763506775	yfinance
872	2026-02-23	EQ.SPX	6837.75	-71.759765625	-1.0385652247284864	yfinance
873	2026-02-24	EQ.SPX	6890.06982421875	52.31982421875	0.7651614086322255	yfinance
874	2026-02-25	EQ.SPX	6946.1298828125	56.06005859375	0.8136355657340022	yfinance
875	2026-02-26	EQ.SPX	6908.85986328125	-37.27001953125	-0.5365580569328384	yfinance
876	2026-02-27	EQ.SPX	6878.8798828125	-29.97998046875	-0.4339352811031182	yfinance
877	2026-03-02	EQ.SPX	6881.6201171875	2.740234375	0.039835473531769645	yfinance
878	2026-03-03	EQ.SPX	6816.6298828125	-64.990234375	-0.9444031095625391	yfinance
879	2026-03-04	EQ.SPX	6869.5	52.8701171875	0.7756049264286315	yfinance
880	2026-03-05	EQ.SPX	6830.7099609375	-38.7900390625	-0.5646704863891113	yfinance
881	2026-03-06	EQ.SPX	6740.02001953125	-90.68994140625	-1.327679581256924	yfinance
882	2026-02-09	EQ.SX7E	6059.009765625	\N	\N	yfinance
883	2026-02-10	EQ.SX7E	6047.06005859375	-11.94970703125	-0.19722211208579166	yfinance
884	2026-02-11	EQ.SX7E	6035.64013671875	-11.419921875	-0.1888508095561352	yfinance
885	2026-02-12	EQ.SX7E	6011.2900390625	-24.35009765625	-0.40343852689480963	yfinance
886	2026-02-13	EQ.SX7E	5985.22998046875	-26.06005859375	-0.43351856963159	yfinance
887	2026-02-16	EQ.SX7E	5978.8798828125	-6.35009765625	-0.10609613460087418	yfinance
888	2026-02-17	EQ.SX7E	6021.85009765625	42.97021484375	0.7187000857347307	yfinance
889	2026-02-18	EQ.SX7E	6103.3701171875	81.52001953125	1.3537371108420353	yfinance
890	2026-02-19	EQ.SX7E	6059.6201171875	-43.75	-0.7168170889193999	yfinance
891	2026-02-20	EQ.SX7E	6131.31005859375	71.68994140625	1.183076496873273	yfinance
892	2026-02-23	EQ.SX7E	6113.919921875	-17.39013671875	-0.28362840163947806	yfinance
893	2026-02-24	EQ.SX7E	6116.60009765625	2.68017578125	0.043837273230560254	yfinance
894	2026-02-25	EQ.SX7E	6173.31982421875	56.7197265625	0.9273080740431892	yfinance
895	2026-02-26	EQ.SX7E	6161.56005859375	-11.759765625	-0.19049338054485504	yfinance
896	2026-02-27	EQ.SX7E	6138.41015625	-23.14990234375	-0.37571495081772344	yfinance
897	2026-03-02	EQ.SX7E	5986.93017578125	-151.47998046875	-2.4677396363701156	yfinance
898	2026-03-03	EQ.SX7E	5771.72998046875	-215.2001953125	-3.5944998353754474	yfinance
899	2026-03-04	EQ.SX7E	5870.919921875	99.18994140625	1.718547848598321	yfinance
900	2026-03-05	EQ.SX7E	5782.89013671875	-88.02978515625	-1.4994206415293068	yfinance
901	2026-03-06	EQ.SX7E	5719.89990234375	-62.990234375	-1.0892517908137378	yfinance
902	2026-02-09	EQ.VIX	17.360000610351562	\N	\N	yfinance
903	2026-02-10	EQ.VIX	17.790000915527344	0.43000030517578125	2.476960196184424	yfinance
904	2026-02-11	EQ.VIX	17.649999618530273	-0.1400012969970703	-0.7869662158076415	yfinance
905	2026-02-12	EQ.VIX	20.81999969482422	3.1700000762939453	17.960340763780216	yfinance
906	2026-02-13	EQ.VIX	20.600000381469727	-0.2199993133544922	-1.056672990293959	yfinance
907	2026-02-17	EQ.VIX	20.290000915527344	-0.3099994659423828	-1.5048517485525679	yfinance
908	2026-02-18	EQ.VIX	19.6200008392334	-0.6700000762939453	-3.3021194975955566	yfinance
909	2026-02-19	EQ.VIX	20.229999542236328	0.6099987030029297	3.109065631552561	yfinance
910	2026-02-20	EQ.VIX	19.09000015258789	-1.1399993896484375	-5.635192365023732	yfinance
911	2026-02-23	EQ.VIX	21.010000228881836	1.9200000762939453	10.05762211077649	yfinance
912	2026-02-24	EQ.VIX	19.549999237060547	-1.460000991821289	-6.949076515545527	yfinance
913	2026-02-25	EQ.VIX	17.93000030517578	-1.6199989318847656	-8.286439872661303	yfinance
914	2026-02-26	EQ.VIX	18.6299991607666	0.6999988555908203	3.904064939635023	yfinance
915	2026-02-27	EQ.VIX	19.860000610351562	1.230001449584961	6.602262506673929	yfinance
916	2026-03-02	EQ.VIX	21.440000534057617	1.5799999237060547	7.955689200142907	yfinance
917	2026-03-03	EQ.VIX	23.56999969482422	2.1299991607666016	9.934697330735045	yfinance
918	2026-03-04	EQ.VIX	21.149999618530273	-2.4200000762939453	-10.267289383229638	yfinance
919	2026-03-05	EQ.VIX	23.75	2.6000003814697266	12.293146233401218	yfinance
920	2026-03-06	EQ.VIX	29.489999771118164	5.739999771118164	24.168420088918584	yfinance
921	2026-02-09	EQ.SPY	693.9500122070312	\N	\N	yfinance
922	2026-02-10	EQ.SPY	692.1199951171875	-1.83001708984375	-0.2637102179771686	yfinance
923	2026-02-11	EQ.SPY	691.9600219726562	-0.15997314453125	-0.0231134984771194	yfinance
924	2026-02-12	EQ.SPY	681.27001953125	-10.69000244140625	-1.5448872914552108	yfinance
925	2026-02-13	EQ.SPY	681.75	0.47998046875	0.07045377823616135	yfinance
926	2026-02-17	EQ.SPY	682.8499755859375	1.0999755859375	0.16134588719288595	yfinance
927	2026-02-18	EQ.SPY	686.2899780273438	3.44000244140625	0.5037713354905614	yfinance
928	2026-02-19	EQ.SPY	684.47998046875	-1.80999755859375	-0.2637365569283651	yfinance
929	2026-02-20	EQ.SPY	689.4299926757812	4.95001220703125	0.7231785221302383	yfinance
930	2026-02-23	EQ.SPY	682.3900146484375	-7.03997802734375	-1.021130223827446	yfinance
931	2026-02-24	EQ.SPY	687.3499755859375	4.9599609375	0.7268513358970143	yfinance
932	2026-02-25	EQ.SPY	693.1500244140625	5.800048828125	0.8438276037153705	yfinance
933	2026-02-26	EQ.SPY	689.2999877929688	-3.85003662109375	-0.5554405951797066	yfinance
934	2026-02-27	EQ.SPY	685.989990234375	-3.30999755859375	-0.48019695592797657	yfinance
935	2026-03-02	EQ.SPY	686.3800048828125	0.3900146484375	0.056854276882997636	yfinance
936	2026-03-03	EQ.SPY	680.3300170898438	-6.04998779296875	-0.8814341545397554	yfinance
937	2026-03-04	EQ.SPY	685.1300048828125	4.79998779296875	0.7055381465455562	yfinance
938	2026-03-05	EQ.SPY	681.3099975585938	-3.82000732421875	-0.5575594846225046	yfinance
939	2026-03-06	EQ.SPY	672.3800048828125	-8.92999267578125	-1.3107091790493293	yfinance
940	2026-02-09	EQ.LQD	110.18083953857422	\N	\N	yfinance
941	2026-02-10	EQ.LQD	110.43994903564453	0.2591094970703125	0.23516747390511442	yfinance
942	2026-02-11	EQ.LQD	110.32035827636719	-0.11959075927734375	-0.1082857791239525	yfinance
943	2026-02-12	EQ.LQD	110.83858489990234	0.5182266235351562	0.4697470454518735	yfinance
944	2026-02-13	EQ.LQD	111.20730590820312	0.36872100830078125	0.33266484648263145	yfinance
945	2026-02-17	EQ.LQD	111.31693267822266	0.10962677001953125	0.09857874815349224	yfinance
946	2026-02-18	EQ.LQD	111.20730590820312	-0.10962677001953125	-0.09848166615983117	yfinance
947	2026-02-19	EQ.LQD	111.29700469970703	0.08969879150390625	0.08065908149771092	yfinance
948	2026-02-20	EQ.LQD	111.20730590820312	-0.08969879150390625	-0.08059407505702834	yfinance
949	2026-02-23	EQ.LQD	111.32689666748047	0.11959075927734375	0.1075385814813829	yfinance
950	2026-02-24	EQ.LQD	111.29700469970703	-0.0298919677734375	-0.026850625202210633	yfinance
951	2026-02-25	EQ.LQD	111.26710510253906	-0.02989959716796875	-0.026864691685676116	yfinance
952	2026-02-26	EQ.LQD	111.33686828613281	0.06976318359375	0.06269883945435553	yfinance
953	2026-02-27	EQ.LQD	111.29700469970703	-0.03986358642578125	-0.03580447971945186	yfinance
954	2026-03-02	EQ.LQD	110.91999816894531	-0.37700653076171875	-0.3387391527552144	yfinance
955	2026-03-03	EQ.LQD	110.87000274658203	-0.04999542236328125	-0.045073407130003594	yfinance
956	2026-03-04	EQ.LQD	110.97000122070312	0.09999847412109375	0.09019434621072611	yfinance
957	2026-03-05	EQ.LQD	110.52999877929688	-0.44000244140625	-0.3965057552186103	yfinance
958	2026-03-06	EQ.LQD	110.16000366210938	-0.3699951171875	-0.33474633246517593	yfinance
959	2026-02-09	EQ.HYG	80.5250244140625	\N	\N	yfinance
960	2026-02-10	EQ.HYG	80.4454116821289	-0.07961273193359375	-0.09886706960090107	yfinance
961	2026-02-11	EQ.HYG	80.43546295166016	-0.00994873046875	-0.012367057686349225	yfinance
962	2026-02-12	EQ.HYG	80.39566040039062	-0.03980255126953125	-0.049483834379683574	yfinance
963	2026-02-13	EQ.HYG	80.45536041259766	0.05970001220703125	0.07425775459733792	yfinance
964	2026-02-17	EQ.HYG	80.41555786132812	-0.03980255126953125	-0.04947159650446235	yfinance
965	2026-02-18	EQ.HYG	80.51507568359375	0.099517822265625	0.12375443870853647	yfinance
966	2026-02-19	EQ.HYG	80.54492950439453	0.02985382080078125	0.03707854777172426	yfinance
967	2026-02-20	EQ.HYG	80.60462951660156	0.05970001220703125	0.07412013713883009	yfinance
968	2026-02-23	EQ.HYG	80.47527313232422	-0.12935638427734375	-0.160482574081804	yfinance
969	2026-02-24	EQ.HYG	80.41555786132812	-0.05971527099609375	-0.07420325358561365	yfinance
970	2026-02-25	EQ.HYG	80.5250244140625	0.109466552734375	0.1361260875950691	yfinance
971	2026-02-26	EQ.HYG	80.45536041259766	-0.06966400146484375	-0.08651223886208219	yfinance
972	2026-02-27	EQ.HYG	80.32599639892578	-0.129364013671875	-0.1607898007149058	yfinance
973	2026-03-02	EQ.HYG	80.27999877929688	-0.04599761962890625	-0.05726367762743543	yfinance
974	2026-03-03	EQ.HYG	80.12000274658203	-0.15999603271484375	-0.19929750267522994	yfinance
975	2026-03-04	EQ.HYG	80.4000015258789	0.279998779296875	0.34947425074672744	yfinance
976	2026-03-05	EQ.HYG	80.08000183105469	-0.31999969482421875	-0.39800956312322733	yfinance
977	2026-03-06	EQ.HYG	79.69000244140625	-0.3899993896484375	-0.4870122137000219	yfinance
978	2026-02-09	EQ.IEAC	120.05000305175781	\N	\N	yfinance
979	2026-02-10	EQ.IEAC	120.16000366210938	0.1100006103515625	0.09162899421513329	yfinance
980	2026-02-11	EQ.IEAC	120.18000030517578	0.01999664306640625	0.016641679807731135	yfinance
981	2026-02-12	EQ.IEAC	120.2300033569336	0.0500030517578125	0.04160679949312583	yfinance
982	2026-02-13	EQ.IEAC	120.30000305175781	0.06999969482421875	0.05822148620956676	yfinance
983	2026-02-16	EQ.IEAC	120.26000213623047	-0.04000091552734375	-0.03325096800715273	yfinance
984	2026-02-17	EQ.IEAC	120.29499816894531	0.03499603271484375	0.02910030940727929	yfinance
985	2026-02-18	EQ.IEAC	120.33000183105469	0.035003662109375	0.029098185828320956	yfinance
986	2026-02-19	EQ.IEAC	120.30000305175781	-0.029998779296875	-0.024930423701807786	yfinance
987	2026-02-20	EQ.IEAC	120.36000061035156	0.05999755859375	0.04987328102388882	yfinance
988	2026-02-23	EQ.IEAC	120.5	0.1399993896484375	0.11631720583125092	yfinance
989	2026-02-24	EQ.IEAC	120.44999694824219	-0.0500030517578125	-0.04149630851270747	yfinance
990	2026-02-25	EQ.IEAC	120.47000122070312	0.0200042724609375	0.016607947669383016	yfinance
991	2026-02-26	EQ.IEAC	120.47000122070312	0	0	yfinance
992	2026-02-27	EQ.IEAC	120.55000305175781	0.0800018310546875	0.06640809350381159	yfinance
993	2026-03-02	EQ.IEAC	120.12000274658203	-0.43000030517578125	-0.3566987094900046	yfinance
994	2026-03-03	EQ.IEAC	119.62999725341797	-0.4900054931640625	-0.4079299716616144	yfinance
995	2026-03-04	EQ.IEAC	120.12000274658203	0.4900054931640625	0.40960085631872106	yfinance
996	2026-03-05	EQ.IEAC	119.48999786376953	-0.6300048828125	-0.5244795774286032	yfinance
997	2026-03-06	EQ.IEAC	119.12000274658203	-0.3699951171875	-0.3096452621995451	yfinance
998	2026-02-09	EQ.IWM	266.8800048828125	\N	\N	yfinance
999	2026-02-10	EQ.IWM	266.1600036621094	-0.720001220703125	-0.2697846251236689	yfinance
1000	2026-02-11	EQ.IWM	264.95001220703125	-1.209991455078125	-0.4546105494551358	yfinance
1001	2026-02-12	EQ.IWM	259.5400085449219	-5.410003662109375	-2.0418959852253233	yfinance
1002	2026-02-13	EQ.IWM	262.9599914550781	3.41998291015625	1.3177093309543875	yfinance
1003	2026-02-17	EQ.IWM	263.0400085449219	0.08001708984375	0.030429378020960064	yfinance
1004	2026-02-18	EQ.IWM	263.989990234375	0.949981689453125	0.36115482762801365	yfinance
1005	2026-02-19	EQ.IWM	264.6000061035156	0.610015869140625	0.23107537850167806	yfinance
1006	2026-02-20	EQ.IWM	264.6099853515625	0.009979248046875	0.0037714466427377796	yfinance
1007	2026-02-23	EQ.IWM	260.489990234375	-4.1199951171875	-1.5570066684043116	yfinance
1008	2026-02-24	EQ.IWM	263.3299865722656	2.839996337890625	1.090251619778306	yfinance
1009	2026-02-25	EQ.IWM	264.5799865722656	1.25	0.47468957723770766	yfinance
1010	2026-02-26	EQ.IWM	265.989990234375	1.410003662109375	0.5329215109489228	yfinance
1011	2026-02-27	EQ.IWM	261.4100036621094	-4.579986572265625	-1.7218642582113732	yfinance
1012	2026-03-02	EQ.IWM	263.80999755859375	2.399993896484375	0.9180956592566114	yfinance
1013	2026-03-03	EQ.IWM	259.239990234375	-4.57000732421875	-1.7323101347604253	yfinance
1014	2026-03-04	EQ.IWM	261.760009765625	2.52001953125	0.9720797817388004	yfinance
1015	2026-03-05	EQ.IWM	256.760009765625	-5	-1.9101466280036077	yfinance
1016	2026-03-06	EQ.IWM	250.88999938964844	-5.8700103759765625	-2.286185602397667	yfinance
1017	2026-02-09	CM.WTI	64.36000061035156	\N	\N	yfinance
1018	2026-02-10	CM.WTI	63.959999084472656	-0.40000152587890625	-0.6215064047320265	yfinance
1019	2026-02-11	CM.WTI	64.62999725341797	0.6699981689453125	1.047526858248448	yfinance
1020	2026-02-12	CM.WTI	62.84000015258789	-1.7899971008300781	-2.7696072673674976	yfinance
1021	2026-02-13	CM.WTI	62.88999938964844	0.049999237060546875	0.07956594038691739	yfinance
1022	2026-02-17	CM.WTI	62.33000183105469	-0.55999755859375	-0.8904397583535745	yfinance
1023	2026-02-18	CM.WTI	65.19000244140625	2.8600006103515625	4.588481511846553	yfinance
1024	2026-02-19	CM.WTI	66.43000030517578	1.2399978637695312	1.902128880703847	yfinance
1025	2026-02-20	CM.WTI	66.38999938964844	-0.04000091552734375	-0.06021513675083808	yfinance
1026	2026-02-23	CM.WTI	66.30999755859375	-0.0800018310546875	-0.12050283444822779	yfinance
1027	2026-02-24	CM.WTI	65.62999725341797	-0.6800003051757812	-1.025486849965437	yfinance
1028	2026-02-25	CM.WTI	65.41999816894531	-0.20999908447265625	-0.31997423931283137	yfinance
1029	2026-02-26	CM.WTI	65.20999908447266	-0.20999908447265625	-0.3210013609757975	yfinance
1030	2026-02-27	CM.WTI	67.0199966430664	1.80999755859375	2.775644201818021	yfinance
1031	2026-03-02	CM.WTI	71.2300033569336	4.2100067138671875	6.281717285497263	yfinance
1032	2026-03-03	CM.WTI	74.55999755859375	3.3299942016601562	4.6749881296138	yfinance
1033	2026-03-04	CM.WTI	74.66000366210938	0.100006103515625	0.1341283621113777	yfinance
1034	2026-03-05	CM.WTI	81.01000213623047	6.349998474121094	8.505221219730231	yfinance
1035	2026-03-06	CM.WTI	90.9000015258789	9.889999389648438	12.208368261757258	yfinance
1036	2026-02-09	CM.BRENT	69.04000091552734	\N	\N	yfinance
1037	2026-02-10	CM.BRENT	68.80000305175781	-0.23999786376953125	-0.347621466667094	yfinance
1038	2026-02-11	CM.BRENT	69.4000015258789	0.5999984741210938	0.8720907667252844	yfinance
1039	2026-02-12	CM.BRENT	67.5199966430664	-1.8800048828125	-2.708940693771391	yfinance
1040	2026-02-13	CM.BRENT	67.75	0.23000335693359375	0.3406447991244275	yfinance
1041	2026-02-17	CM.BRENT	67.41999816894531	-0.3300018310546875	-0.48708757351245385	yfinance
1042	2026-02-18	CM.BRENT	70.3499984741211	2.9300003051757812	4.345891997554792	yfinance
1043	2026-02-19	CM.BRENT	71.66000366210938	1.3100051879882812	1.8621253964492679	yfinance
1044	2026-02-20	CM.BRENT	71.76000213623047	0.09999847412109375	0.1395457284548933	yfinance
1045	2026-02-23	CM.BRENT	71.48999786376953	-0.2700042724609375	-0.3762601232206718	yfinance
1046	2026-02-24	CM.BRENT	70.7699966430664	-0.720001220703125	-1.007135602486869	yfinance
1047	2026-02-25	CM.BRENT	70.8499984741211	0.0800018310546875	0.11304484223474323	yfinance
1048	2026-02-26	CM.BRENT	70.75	-0.09999847412109375	-0.1411411097737984	yfinance
1049	2026-02-27	CM.BRENT	72.4800033569336	1.7300033569335938	2.4452344267612633	yfinance
1050	2026-03-02	CM.BRENT	77.73999786376953	5.2599945068359375	7.257166477949335	yfinance
1051	2026-03-03	CM.BRENT	81.4000015258789	3.660003662109375	4.708005869157745	yfinance
1052	2026-03-04	CM.BRENT	81.4000015258789	0	0	yfinance
1053	2026-03-05	CM.BRENT	85.41000366210938	4.010002136230469	4.926292458306157	yfinance
1054	2026-03-06	CM.BRENT	92.69000244140625	7.279998779296875	8.523590290544053	yfinance
1055	2026-02-09	CM.GOLD	5050.89990234375	\N	\N	yfinance
1056	2026-02-10	CM.GOLD	5003.7998046875	-47.10009765625	-0.9325090294185858	yfinance
1057	2026-02-11	CM.GOLD	5071.60009765625	67.80029296875	1.3549761304446173	yfinance
1058	2026-02-12	CM.GOLD	4923.7001953125	-147.89990234375	-2.916237469356058	yfinance
1059	2026-02-13	CM.GOLD	5022	98.2998046875	1.9964620262843005	yfinance
1060	2026-02-17	CM.GOLD	4882.89990234375	-139.10009765625	-2.7698147681451615	yfinance
1061	2026-02-18	CM.GOLD	4986.5	103.60009765625	2.1216920217128115	yfinance
1062	2026-02-19	CM.GOLD	4975.89990234375	-10.60009765625	-0.21257590807680737	yfinance
1063	2026-02-20	CM.GOLD	5059.2998046875	83.39990234375	1.6760767696405419	yfinance
1064	2026-02-23	CM.GOLD	5204.7001953125	145.400390625	2.8739231956620728	yfinance
1065	2026-02-24	CM.GOLD	5155.7998046875	-48.900390625	-0.9395428898871269	yfinance
1066	2026-02-25	CM.GOLD	5206.39990234375	50.60009765625	0.98142091572768	yfinance
1067	2026-02-26	CM.GOLD	5176.5	-29.89990234375	-0.5742913127032375	yfinance
1068	2026-02-27	CM.GOLD	5230.5	54	1.0431758910460736	yfinance
1069	2026-03-02	CM.GOLD	5294.39990234375	63.89990234375	1.2216786606203995	yfinance
1070	2026-03-03	CM.GOLD	5107.39990234375	-187	-3.5320339122327717	yfinance
1071	2026-03-04	CM.GOLD	5120.2001953125	12.80029296875	0.2506224931178002	yfinance
1072	2026-03-05	CM.GOLD	5065.2998046875	-54.900390625	-1.0722313294558452	yfinance
1073	2026-03-06	CM.GOLD	5146.10009765625	80.80029296875	1.5951729627923754	yfinance
1074	2026-02-09	CM.COPPER	5.945000171661377	\N	\N	yfinance
1075	2026-02-10	CM.COPPER	5.895999908447266	-0.04900026321411133	-0.8242264390114865	yfinance
1076	2026-02-11	CM.COPPER	5.948999881744385	0.05299997329711914	0.8989140793775366	yfinance
1077	2026-02-12	CM.COPPER	5.770999908447266	-0.17799997329711914	-2.9920991231374074	yfinance
1078	2026-02-13	CM.COPPER	5.792500019073486	0.021500110626220703	0.37255434010231137	yfinance
1079	2026-02-17	CM.COPPER	5.632999897003174	-0.1595001220703125	-2.7535627370757374	yfinance
1080	2026-02-18	CM.COPPER	5.793499946594238	0.16050004959106445	2.849281955010375	yfinance
1081	2026-02-19	CM.COPPER	5.730000019073486	-0.06349992752075195	-1.0960546838026808	yfinance
1082	2026-02-20	CM.COPPER	5.830999851226807	0.10099983215332031	1.7626497699323131	yfinance
1083	2026-02-23	CM.COPPER	5.7729997634887695	-0.05800008773803711	-0.9946851177818886	yfinance
1084	2026-02-24	CM.COPPER	5.922999858856201	0.15000009536743164	2.598304200809161	yfinance
1085	2026-02-25	CM.COPPER	5.979499816894531	0.05649995803833008	0.9539078065965185	yfinance
1086	2026-02-26	CM.COPPER	5.947000026702881	-0.03249979019165039	-0.5435202138450644	yfinance
1087	2026-02-27	CM.COPPER	6.004499912261963	0.05749988555908203	0.9668721254565212	yfinance
1088	2026-03-02	CM.COPPER	5.894499778747559	-0.1100001335144043	-1.8319616141515773	yfinance
1089	2026-03-03	CM.COPPER	5.773499965667725	-0.12099981307983398	-2.0527579543915695	yfinance
1090	2026-03-04	CM.COPPER	5.855000019073486	0.08150005340576172	1.41162299974719	yfinance
1091	2026-03-05	CM.COPPER	5.752999782562256	-0.10200023651123047	-1.7421048023731913	yfinance
1092	2026-03-06	CM.COPPER	5.756999969482422	0.004000186920166016	0.06953219314019203	yfinance
1093	2026-02-09	CM.NATGAS	3.138000011444092	\N	\N	yfinance
1094	2026-02-10	CM.NATGAS	3.115000009536743	-0.023000001907348633	-0.732950982264788	yfinance
1095	2026-02-11	CM.NATGAS	3.1589999198913574	0.04399991035461426	1.4125171820194582	yfinance
1096	2026-02-12	CM.NATGAS	3.2170000076293945	0.05800008773803711	1.8360268822049168	yfinance
1097	2026-02-13	CM.NATGAS	3.243000030517578	0.026000022888183594	0.8082071130407922	yfinance
1098	2026-02-17	CM.NATGAS	3.0309998989105225	-0.21200013160705566	-6.5371609501101595	yfinance
1099	2026-02-18	CM.NATGAS	3.010999917984009	-0.019999980926513672	-0.6598476276328008	yfinance
1100	2026-02-19	CM.NATGAS	2.996000051498413	-0.014999866485595703	-0.4981689436789738	yfinance
1101	2026-02-20	CM.NATGAS	3.046999931335449	0.05099987983703613	1.7022656528837228	yfinance
1102	2026-02-23	CM.NATGAS	2.984999895095825	-0.06200003623962402	-2.0347895515852685	yfinance
1103	2026-02-24	CM.NATGAS	2.9149999618530273	-0.06999993324279785	-2.345056472457621	yfinance
1104	2026-02-25	CM.NATGAS	2.9690001010894775	0.054000139236450195	1.852491936299135	yfinance
1105	2026-02-26	CM.NATGAS	2.8269999027252197	-0.1420001983642578	-4.782761654745337	yfinance
1106	2026-02-27	CM.NATGAS	2.8589999675750732	0.032000064849853516	1.131944320868407	yfinance
1107	2026-03-02	CM.NATGAS	2.9600000381469727	0.10100007057189941	3.53270625104501	yfinance
1108	2026-03-03	CM.NATGAS	3.053999900817871	0.09399986267089844	3.175670995252571	yfinance
1109	2026-03-04	CM.NATGAS	2.9170000553131104	-0.13699984550476074	-4.4859151916826105	yfinance
1110	2026-03-05	CM.NATGAS	3.003000020980835	0.08599996566772461	2.948233254609705	yfinance
1111	2026-03-06	CM.NATGAS	3.186000108718872	0.1830000877380371	6.093908973009794	yfinance
1112	2026-02-09	FX.EURUSD	1.182578206062317	\N	\N	yfinance
1113	2026-02-10	FX.EURUSD	1.1904053688049316	0.007827162742614746	0.6618727372523798	yfinance
1114	2026-02-11	FX.EURUSD	1.1889617443084717	-0.001443624496459961	-0.12127167217913679	yfinance
1115	2026-02-12	FX.EURUSD	1.1876062154769897	-0.0013555288314819336	-0.11400945724038761	yfinance
1116	2026-02-13	FX.EURUSD	1.1868449449539185	-0.0007612705230712891	-0.0641012579043747	yfinance
1117	2026-02-16	FX.EURUSD	1.1867464780807495	-9.846687316894531e-05	-0.00829652378666604	yfinance
1118	2026-02-17	FX.EURUSD	1.1849884986877441	-0.001757979393005371	-0.14813436782626402	yfinance
1119	2026-02-18	FX.EURUSD	1.185185194015503	0.00019669532775878906	0.016598922941160138	yfinance
1120	2026-02-19	FX.EURUSD	1.1788839101791382	-0.006301283836364746	-0.5316708197320191	yfinance
1121	2026-02-20	FX.EURUSD	1.1769136190414429	-0.0019702911376953125	-0.1671319050741744	yfinance
1122	2026-02-23	FX.EURUSD	1.1834739446640015	0.006560325622558594	0.5574177676609573	yfinance
1123	2026-02-24	FX.EURUSD	1.1793843507766724	-0.0040895938873291016	-0.3455584219465155	yfinance
1124	2026-02-25	FX.EURUSD	1.1775233745574951	-0.001860976219177246	-0.15779217504045376	yfinance
1125	2026-02-26	FX.EURUSD	1.181516408920288	0.003993034362792969	0.33910446697446855	yfinance
1126	2026-02-27	FX.EURUSD	1.1803030967712402	-0.0012133121490478516	-0.10269109594141139	yfinance
1127	2026-03-02	FX.EURUSD	1.1759449243545532	-0.004358172416687012	-0.36924180141600427	yfinance
1128	2026-03-03	FX.EURUSD	1.1697274446487427	-0.006217479705810547	-0.5287220155504447	yfinance
1129	2026-03-04	FX.EURUSD	1.161224365234375	-0.008503079414367676	-0.7269282646369868	yfinance
1130	2026-03-05	FX.EURUSD	1.1635618209838867	0.0023374557495117188	0.20129234448503325	yfinance
1131	2026-03-06	FX.EURUSD	1.1608065366744995	-0.002755284309387207	-0.23679741460212134	yfinance
1132	2026-02-09	FX.GBPUSD	1.3608959913253784	\N	\N	yfinance
1133	2026-02-10	FX.GBPUSD	1.368344783782959	0.007448792457580566	0.5473447276691716	yfinance
1134	2026-02-11	FX.GBPUSD	1.3634566068649292	-0.004888176918029785	-0.35723283897175484	yfinance
1135	2026-02-12	FX.GBPUSD	1.362399697303772	-0.0010569095611572266	-0.07751691955840362	yfinance
1136	2026-02-13	FX.GBPUSD	1.3620266914367676	-0.00037300586700439453	-0.027378592915323147	yfinance
1137	2026-02-16	FX.GBPUSD	1.3647778034210205	0.0027511119842529297	0.20198664251952736	yfinance
1138	2026-02-17	FX.GBPUSD	1.3627691268920898	-0.002008676528930664	-0.14717974778719398	yfinance
1139	2026-02-18	FX.GBPUSD	1.3564472198486328	-0.006321907043457031	-0.4639015456620062	yfinance
1140	2026-02-19	FX.GBPUSD	1.349582314491272	-0.00686490535736084	-0.5060945429286147	yfinance
1141	2026-02-20	FX.GBPUSD	1.3461124897003174	-0.00346982479095459	-0.25710360558944845	yfinance
1142	2026-02-23	FX.GBPUSD	1.3533265590667725	0.007214069366455078	0.5359187602561457	yfinance
1143	2026-02-24	FX.GBPUSD	1.34969162940979	-0.003634929656982422	-0.26859220582273935	yfinance
1144	2026-02-25	FX.GBPUSD	1.3497462272644043	5.459785461425781e-05	0.004045209544504106	yfinance
1145	2026-02-26	FX.GBPUSD	1.3558034896850586	0.006057262420654297	0.4487704650177717	yfinance
1146	2026-02-27	FX.GBPUSD	1.3491452932357788	-0.006658196449279785	-0.49108860538679	yfinance
1147	2026-03-02	FX.GBPUSD	1.3406623601913452	-0.008482933044433594	-0.6287634910016399	yfinance
1148	2026-03-03	FX.GBPUSD	1.3410578966140747	0.0003955364227294922	0.029503060164457775	yfinance
1149	2026-03-04	FX.GBPUSD	1.3353630304336548	-0.005694866180419922	-0.42465475911207223	yfinance
1150	2026-03-05	FX.GBPUSD	1.3369520902633667	0.001589059829711914	0.1189983392902432	yfinance
1151	2026-03-06	FX.GBPUSD	1.3357375860214233	-0.0012145042419433594	-0.09084126879251998	yfinance
1152	2026-02-09	FX.USDJPY	157.24400329589844	\N	\N	yfinance
1153	2026-02-10	FX.USDJPY	156.1320037841797	-1.11199951171875	-0.7071808707555053	yfinance
1154	2026-02-11	FX.USDJPY	154.48199462890625	-1.6500091552734375	-1.0568039321100593	yfinance
1155	2026-02-12	FX.USDJPY	153.2689971923828	-1.2129974365234375	-0.7852031166721256	yfinance
1156	2026-02-13	FX.USDJPY	152.8209991455078	-0.447998046875	-0.2922952815517375	yfinance
1157	2026-02-16	FX.USDJPY	152.7790069580078	-0.0419921875	-0.027478021826056333	yfinance
1158	2026-02-17	FX.USDJPY	153.60899353027344	0.829986572265625	0.5432595673918417	yfinance
1159	2026-02-18	FX.USDJPY	153.1490020751953	-0.459991455078125	-0.2994560699256644	yfinance
1160	2026-02-19	FX.USDJPY	154.6929931640625	1.5439910888671875	1.008162683364464	yfinance
1161	2026-02-20	FX.USDJPY	155.16000366210938	0.467010498046875	0.3018950558100446	yfinance
1162	2026-02-23	FX.USDJPY	154.33900451660156	-0.8209991455078125	-0.5291306561810191	yfinance
1163	2026-02-24	FX.USDJPY	154.63499450683594	0.295989990234375	0.19177912359965796	yfinance
1164	2026-02-25	FX.USDJPY	155.8800048828125	1.2450103759765625	0.8051284768671974	yfinance
1165	2026-02-26	FX.USDJPY	156.1999969482422	0.3199920654296875	0.20528102091750075	yfinance
1166	2026-02-27	FX.USDJPY	155.85899353027344	-0.34100341796875	-0.2183120516204258	yfinance
1167	2026-03-02	FX.USDJPY	156.63299560546875	0.7740020751953125	0.4966040506638928	yfinance
1168	2026-03-03	FX.USDJPY	157.2570037841797	0.6240081787109375	0.39838871516107977	yfinance
1169	2026-03-04	FX.USDJPY	157.7729949951172	0.5159912109375	0.32811970120303763	yfinance
1170	2026-03-05	FX.USDJPY	156.98300170898438	-0.7899932861328125	-0.500715148468381	yfinance
1171	2026-03-06	FX.USDJPY	157.53399658203125	0.550994873046875	0.35099014991974176	yfinance
1172	2026-02-09	FX.DXY	96.81999969482422	\N	\N	yfinance
1173	2026-02-10	FX.DXY	96.80000305175781	-0.01999664306640625	-0.02065342194736159	yfinance
1174	2026-02-11	FX.DXY	96.83000183105469	0.029998779296875	0.03099047350322397	yfinance
1175	2026-02-12	FX.DXY	96.93000030517578	0.09999847412109375	0.10327220100188296	yfinance
1176	2026-02-13	FX.DXY	96.87999725341797	-0.0500030517578125	-0.05158676529493674	yfinance
1177	2026-02-17	FX.DXY	97.16000366210938	0.28000640869140625	0.28902396431635685	yfinance
1178	2026-02-18	FX.DXY	97.69999694824219	0.5399932861328125	0.5557773423009864	yfinance
1179	2026-02-19	FX.DXY	97.93000030517578	0.23000335693359375	0.23541797760284572	yfinance
1180	2026-02-20	FX.DXY	97.80000305175781	-0.12999725341796875	-0.13274507608788208	yfinance
1181	2026-02-23	FX.DXY	97.69999694824219	-0.100006103515625	-0.10225572637528413	yfinance
1182	2026-02-24	FX.DXY	97.87999725341797	0.18000030517578125	0.18423777973211064	yfinance
1183	2026-02-25	FX.DXY	97.69999694824219	-0.18000030517578125	-0.18389896835586153	yfinance
1184	2026-02-26	FX.DXY	97.79000091552734	0.09000396728515625	0.09212279436696093	yfinance
1185	2026-02-27	FX.DXY	97.61000061035156	-0.18000030517578125	-0.18406821095263978	yfinance
1186	2026-03-02	FX.DXY	98.37999725341797	0.7699966430664062	0.7888501570040436	yfinance
1187	2026-03-03	FX.DXY	99.05000305175781	0.6700057983398438	0.6810386430627452	yfinance
1188	2026-03-04	FX.DXY	98.7699966430664	-0.28000640869140625	-0.28269197381557987	yfinance
1189	2026-03-05	FX.DXY	99.31999969482422	0.5500030517578125	0.556852354410222	yfinance
1190	2026-03-06	FX.DXY	98.98999786376953	-0.3300018310546875	-0.33226120828500627	yfinance
1191	2026-02-09	EQ.XLE	53.63999938964844	\N	\N	yfinance
1192	2026-02-10	EQ.XLE	53.58000183105469	-0.05999755859375	-0.11185227307315827	yfinance
1193	2026-02-11	EQ.XLE	54.97999954223633	1.3999977111816406	2.6129109058189868	yfinance
1194	2026-02-12	EQ.XLE	53.97999954223633	-1	-1.8188432308585005	yfinance
1195	2026-02-13	EQ.XLE	54.349998474121094	0.3699989318847656	0.6854370785891952	yfinance
1196	2026-02-17	EQ.XLE	53.75	-0.5999984741210938	-1.1039530652549783	yfinance
1197	2026-02-18	EQ.XLE	54.779998779296875	1.029998779296875	1.9162767986918605	yfinance
1198	2026-02-19	EQ.XLE	55.18000030517578	0.40000152587890625	0.7301963030164939	yfinance
1199	2026-02-20	EQ.XLE	54.880001068115234	-0.2999992370605469	-0.5436738590093982	yfinance
1200	2026-02-23	EQ.XLE	55.150001525878906	0.2700004577636719	0.4919833318307634	yfinance
1201	2026-02-24	EQ.XLE	55.099998474121094	-0.0500030517578125	-0.09066736241947115	yfinance
1202	2026-02-25	EQ.XLE	54.869998931884766	-0.22999954223632812	-0.41742204828617624	yfinance
1203	2026-02-26	EQ.XLE	55.04999923706055	0.18000030517578125	0.32804867628889944	yfinance
1204	2026-02-27	EQ.XLE	55.91999816894531	0.8699989318847656	1.5803795530283464	yfinance
1205	2026-03-02	EQ.XLE	57.040000915527344	1.1200027465820312	2.0028662075386388	yfinance
1206	2026-03-03	EQ.XLE	56.52000045776367	-0.5200004577636719	-0.9116417416152568	yfinance
1207	2026-03-04	EQ.XLE	56.189998626708984	-0.3300018310546875	-0.5838673538251148	yfinance
1208	2026-03-05	EQ.XLE	56.47999954223633	0.29000091552734375	0.5161077106513696	yfinance
1209	2026-03-06	EQ.XLE	56.56999969482422	0.09000015258789062	0.15934871338054382	yfinance
1210	2026-02-09	EQ.XLF	53.939998626708984	\N	\N	yfinance
1211	2026-02-10	EQ.XLF	53.54999923706055	-0.3899993896484375	-0.7230244708521831	yfinance
1212	2026-02-11	EQ.XLF	52.7400016784668	-0.80999755859375	-1.5126005044518693	yfinance
1213	2026-02-12	EQ.XLF	51.689998626708984	-1.0500030517578125	-1.9909044716365984	yfinance
1214	2026-02-13	EQ.XLF	51.650001525878906	-0.039997100830078125	-0.07737880033413472	yfinance
1215	2026-02-17	EQ.XLF	52.20000076293945	0.5499992370605469	1.0648581235471468	yfinance
1216	2026-02-18	EQ.XLF	52.59000015258789	0.3899993896484375	0.7471252566059849	yfinance
1217	2026-02-19	EQ.XLF	52.150001525878906	-0.4399986267089844	-0.8366583484167048	yfinance
1218	2026-02-20	EQ.XLF	52.4900016784668	0.3400001525878906	0.6519657576983369	yfinance
1219	2026-02-23	EQ.XLF	50.72999954223633	-1.7600021362304688	-3.35302358535165	yfinance
1220	2026-02-24	EQ.XLF	50.97999954223633	0.25	0.49280505077051545	yfinance
1221	2026-02-25	EQ.XLF	51.869998931884766	0.8899993896484375	1.7457814783052	yfinance
1222	2026-02-26	EQ.XLF	52.5	0.6300010681152344	1.2145769830119841	yfinance
1223	2026-02-27	EQ.XLF	51.43000030517578	-1.0699996948242188	-2.0380946568080356	yfinance
1224	2026-03-02	EQ.XLF	51.29999923706055	-0.13000106811523438	-0.2527728317010167	yfinance
1225	2026-03-03	EQ.XLF	51.209999084472656	-0.09000015258789062	-0.17543889654265726	yfinance
1226	2026-03-04	EQ.XLF	51.5	0.29000091552734375	0.5662974432961368	yfinance
1227	2026-03-05	EQ.XLF	51.22999954223633	-0.2700004577636719	-0.524272733521693	yfinance
1228	2026-03-06	EQ.XLF	50.56999969482422	-0.6599998474121094	-1.2883073459096475	yfinance
1229	2026-02-09	EQ.XLU	43.47999954223633	\N	\N	yfinance
1230	2026-02-10	EQ.XLU	44.20000076293945	0.720001220703125	1.655936587588319	yfinance
1231	2026-02-11	EQ.XLU	44.59000015258789	0.3899993896484375	0.8823515450602476	yfinance
1232	2026-02-12	EQ.XLU	45.25	0.6599998474121094	1.4801521532935107	yfinance
1233	2026-02-13	EQ.XLU	46.5	1.25	2.7624309392265194	yfinance
1234	2026-02-17	EQ.XLU	46.380001068115234	-0.11999893188476562	-0.25806221910702287	yfinance
1235	2026-02-18	EQ.XLU	45.61000061035156	-0.7700004577636719	-1.6601993101139072	yfinance
1236	2026-02-19	EQ.XLU	46.11000061035156	0.5	1.0962508075181234	yfinance
1237	2026-02-20	EQ.XLU	46.33000183105469	0.220001220703125	0.47712257165690725	yfinance
1238	2026-02-23	EQ.XLU	46.68000030517578	0.34999847412109375	0.7554467090188892	yfinance
1239	2026-02-24	EQ.XLU	47.20000076293945	0.5200004577636719	1.113968411234169	yfinance
1240	2026-02-25	EQ.XLU	47.36000061035156	0.15999984741210938	0.33898272208872127	yfinance
1241	2026-02-26	EQ.XLU	47.18000030517578	-0.18000030517578125	-0.3800682070439802	yfinance
1242	2026-02-27	EQ.XLU	47.72999954223633	0.5499992370605469	1.1657465737663644	yfinance
1243	2026-03-02	EQ.XLU	47.369998931884766	-0.3600006103515625	-0.7542439007002243	yfinance
1244	2026-03-03	EQ.XLU	47.06999969482422	-0.2999992370605469	-0.6333106266097407	yfinance
1245	2026-03-04	EQ.XLU	47.27000045776367	0.20000076293945312	0.42490071008316804	yfinance
1246	2026-03-05	EQ.XLU	46.900001525878906	-0.3699989318847656	-0.7827351984380966	yfinance
1247	2026-03-06	EQ.XLU	46.7400016784668	-0.15999984741210938	-0.3411510494809328	yfinance
1248	2026-02-09	EQ.EEM	60.5099983215332	\N	\N	yfinance
1249	2026-02-10	EQ.EEM	60.599998474121094	0.09000015258789062	0.148736002453107	yfinance
1250	2026-02-11	EQ.EEM	61.560001373291016	0.9600028991699219	1.584163239838836	yfinance
1251	2026-02-12	EQ.EEM	60.86000061035156	-0.7000007629394531	-1.1371032282711446	yfinance
1252	2026-02-13	EQ.EEM	61.119998931884766	0.2599983215332031	0.4272072279423877	yfinance
1253	2026-02-17	EQ.EEM	60.869998931884766	-0.25	-0.40903142076067883	yfinance
1254	2026-02-18	EQ.EEM	61.189998626708984	0.31999969482421875	0.5257100385073235	yfinance
1255	2026-02-19	EQ.EEM	61.040000915527344	-0.14999771118164062	-0.24513435945097034	yfinance
1256	2026-02-20	EQ.EEM	62.34000015258789	1.2999992370605469	2.1297497011174737	yfinance
1257	2026-02-23	EQ.EEM	61.650001525878906	-0.6899986267089844	-1.1068312881297624	yfinance
1258	2026-02-24	EQ.EEM	62.619998931884766	0.9699974060058594	1.573393969177247	yfinance
1259	2026-02-25	EQ.EEM	63.310001373291016	0.69000244140625	1.1018882995459707	yfinance
1260	2026-02-26	EQ.EEM	62.709999084472656	-0.6000022888183594	-0.9477211748592476	yfinance
1261	2026-02-27	EQ.EEM	62.58000183105469	-0.12999725341796875	-0.2072990835845137	yfinance
1262	2026-03-02	EQ.EEM	61.5	-1.0800018310546875	-1.7257938629825154	yfinance
1263	2026-03-03	EQ.EEM	58.41999816894531	-3.0800018310546875	-5.008133058625508	yfinance
1264	2026-03-04	EQ.EEM	59.04999923706055	0.6300010681152344	1.0783996711080488	yfinance
1265	2026-03-05	EQ.EEM	57.630001068115234	-1.4199981689453125	-2.404738674499598	yfinance
1266	2026-03-06	EQ.EEM	57.31999969482422	-0.3100013732910156	-0.5379166537314696	yfinance
1267	2026-02-09	EQ.GLD	467.0299987792969	\N	\N	yfinance
1268	2026-02-10	EQ.GLD	462.3999938964844	-4.6300048828125	-0.991372052098197	yfinance
1269	2026-02-11	EQ.GLD	467.6300048828125	5.230010986328125	1.1310577541873728	yfinance
1270	2026-02-12	EQ.GLD	451.3900146484375	-16.239990234375	-3.4728289598193602	yfinance
1271	2026-02-13	EQ.GLD	462.6199951171875	11.22998046875	2.487866391438988	yfinance
1272	2026-02-17	EQ.GLD	448.20001220703125	-14.41998291015625	-3.1170254339100683	yfinance
1273	2026-02-18	EQ.GLD	458.2799987792969	10.079986572265625	2.248992926758223	yfinance
1274	2026-02-19	EQ.GLD	459.55999755859375	1.279998779296875	0.27930496262249266	yfinance
1275	2026-02-20	EQ.GLD	468.6199951171875	9.05999755859375	1.9714504323102238	yfinance
1276	2026-02-23	EQ.GLD	481.2799987792969	12.660003662109375	2.7015500392687035	yfinance
1277	2026-02-24	EQ.GLD	474.6099853515625	-6.670013427734375	-1.3858904264985004	yfinance
1278	2026-02-25	EQ.GLD	473.4200134277344	-1.189971923828125	-0.2507262722141561	yfinance
1279	2026-02-26	EQ.GLD	477.4800109863281	4.05999755859375	0.857588915432172	yfinance
1280	2026-02-27	EQ.GLD	483.75	6.269989013671875	1.3131416749195404	yfinance
1281	2026-03-02	EQ.GLD	490	6.25	1.2919896640826873	yfinance
1282	2026-03-03	EQ.GLD	468.1400146484375	-21.8599853515625	-4.461221500318878	yfinance
1283	2026-03-04	EQ.GLD	471.79998779296875	3.65997314453125	0.7818116439543854	yfinance
1284	2026-03-05	EQ.GLD	466.1300048828125	-5.66998291015625	-1.2017768242597546	yfinance
1285	2026-03-06	EQ.GLD	473.510009765625	7.3800048828125	1.5832503390696488	yfinance
1286	2026-02-09	EQ.SLV	76.04000091552734	\N	\N	yfinance
1287	2026-02-10	EQ.SLV	73.41000366210938	-2.6299972534179688	-3.458702290574176	yfinance
1288	2026-02-11	EQ.SLV	76.55999755859375	3.149993896484375	4.2909600045562275	yfinance
1289	2026-02-12	EQ.SLV	67.7300033569336	-8.829994201660156	-11.533430620739358	yfinance
1290	2026-02-13	EQ.SLV	69.72000122070312	1.9899978637695312	2.938133419663876	yfinance
1291	2026-02-17	EQ.SLV	66.37000274658203	-3.3499984741210938	-4.804931749092286	yfinance
1292	2026-02-18	EQ.SLV	70.08999633789062	3.7199935913085938	5.604932103909199	yfinance
1293	2026-02-19	EQ.SLV	71.01000213623047	0.9200057983398438	1.312606429460589	yfinance
1294	2026-02-20	EQ.SLV	76.62000274658203	5.6100006103515625	7.900296354855689	yfinance
1295	2026-02-23	EQ.SLV	80.56999969482422	3.9499969482421875	5.15530776122087	yfinance
1296	2026-02-24	EQ.SLV	79.08000183105469	-1.4899978637695312	-1.8493209251746443	yfinance
1297	2026-02-25	EQ.SLV	80.04000091552734	0.9599990844726562	1.2139593604506784	yfinance
1298	2026-02-26	EQ.SLV	80.44999694824219	0.40999603271484375	0.5122389155736586	yfinance
1299	2026-02-27	EQ.SLV	84.98999786376953	4.540000915527344	5.6432580332453846	yfinance
1300	2026-03-02	EQ.SLV	81.56999969482422	-3.4199981689453125	-4.0240007705697645	yfinance
1301	2026-03-03	EQ.SLV	74.68000030517578	-6.8899993896484375	-8.446732150822383	yfinance
1302	2026-03-04	EQ.SLV	75.33999633789062	0.6599960327148438	0.883765439231127	yfinance
1303	2026-03-05	EQ.SLV	74.2699966430664	-1.0699996948242188	-1.42022796235004	yfinance
1304	2026-03-06	EQ.SLV	75.94000244140625	1.6700057983398438	2.2485604871718405	yfinance
1305	2026-02-09	EQ.XLK	143.35000610351562	\N	\N	yfinance
1306	2026-02-10	EQ.XLK	142.5500030517578	-0.8000030517578125	-0.5580767476076115	yfinance
1307	2026-02-11	EQ.XLK	142.97000122070312	0.4199981689453125	0.29463217113563817	yfinance
1308	2026-02-12	EQ.XLK	139.2100067138672	-3.7599945068359375	-2.629918496700315	yfinance
1309	2026-02-13	EQ.XLK	139.55999755859375	0.3499908447265625	0.25141213120256156	yfinance
1310	2026-02-17	EQ.XLK	139.47999572753906	-0.0800018310546875	-0.057324328213103494	yfinance
1311	2026-02-18	EQ.XLK	140.91000366210938	1.4300079345703125	1.0252423131440993	yfinance
1312	2026-02-19	EQ.XLK	140.2100067138672	-0.6999969482421875	-0.49676880991410854	yfinance
1313	2026-02-20	EQ.XLK	140.8800048828125	0.6699981689453125	0.47785331778252293	yfinance
1314	2026-02-23	EQ.XLK	138.52000427246094	-2.3600006103515625	-1.6751849294118564	yfinance
1315	2026-02-24	EQ.XLK	140.32000732421875	1.8000030517578125	1.299453505803616	yfinance
1316	2026-02-25	EQ.XLK	143.00999450683594	2.6899871826171875	1.917037515827513	yfinance
1317	2026-02-26	EQ.XLK	141.00999450683594	-2	-1.398503654864765	yfinance
1318	2026-02-27	EQ.XLK	138.75999450683594	-2.25	-1.5956315776545353	yfinance
1319	2026-03-02	EQ.XLK	139.5399932861328	0.779998779296875	0.5621207914205046	yfinance
1320	2026-03-03	EQ.XLK	137.5	-2.0399932861328125	-1.4619416542107162	yfinance
1321	2026-03-04	EQ.XLK	139.83999633789062	2.339996337890625	1.7018155184659092	yfinance
1322	2026-03-05	EQ.XLK	140.17999267578125	0.339996337890625	0.24313239902345493	yfinance
1323	2026-03-06	EQ.XLK	137.2899932861328	-2.8899993896484375	-2.061634712974086	yfinance
1324	2026-02-09	EQ.XLV	156.32000732421875	\N	\N	yfinance
1325	2026-02-10	EQ.XLV	155.3300018310547	-0.9900054931640625	-0.6333197586862449	yfinance
1326	2026-02-11	EQ.XLV	156.25	0.9199981689453125	0.5922862023435449	yfinance
1327	2026-02-12	EQ.XLV	156	-0.25	-0.16	yfinance
1328	2026-02-13	EQ.XLV	157.6699981689453	1.6699981689453125	1.0705116467598157	yfinance
1329	2026-02-17	EQ.XLV	157.3699951171875	-0.3000030517578125	-0.19027275654329343	yfinance
1330	2026-02-18	EQ.XLV	157.6699981689453	0.3000030517578125	0.19063548393352336	yfinance
1331	2026-02-19	EQ.XLV	157.25999450683594	-0.410003662109375	-0.26003911135335406	yfinance
1332	2026-02-20	EQ.XLV	156.82000732421875	-0.4399871826171875	-0.2797832875404696	yfinance
1333	2026-02-23	EQ.XLV	158.5399932861328	1.7199859619140625	1.096789874749887	yfinance
1334	2026-02-24	EQ.XLV	157.8699951171875	-0.6699981689453125	-0.4226051452746693	yfinance
1335	2026-02-25	EQ.XLV	157.8300018310547	-0.0399932861328125	-0.02533305084549178	yfinance
1336	2026-02-26	EQ.XLV	157.4199981689453	-0.410003662109375	-0.259775490941357	yfinance
1337	2026-02-27	EQ.XLV	160.1999969482422	2.779998779296875	1.7659756140470424	yfinance
1338	2026-03-02	EQ.XLV	158.52999877929688	-1.6699981689453125	-1.042445818201145	yfinance
1339	2026-03-03	EQ.XLV	156.74000549316406	-1.7899932861328125	-1.1291195987611244	yfinance
1340	2026-03-04	EQ.XLV	157.0500030517578	0.30999755859375	0.19777819811756353	yfinance
1341	2026-03-05	EQ.XLV	153.91000366210938	-3.1399993896484375	-1.9993628326219204	yfinance
1342	2026-03-06	EQ.XLV	152.6999969482422	-1.2100067138671875	-0.7861780813959368	yfinance
1343	2026-02-09	EQ.XLY	117.55000305175781	\N	\N	yfinance
1344	2026-02-10	EQ.XLY	118.33000183105469	0.779998779296875	0.6635463709460202	yfinance
1345	2026-02-11	EQ.XLY	117.76000213623047	-0.5699996948242188	-0.48170344460742437	yfinance
1346	2026-02-12	EQ.XLY	116.12999725341797	-1.6300048828125	-1.384175316952552	yfinance
1347	2026-02-13	EQ.XLY	116.18000030517578	0.0500030517578125	0.04305782566126841	yfinance
1348	2026-02-17	EQ.XLY	116.04000091552734	-0.1399993896484375	-0.12050214260689804	yfinance
1349	2026-02-18	EQ.XLY	117.0199966430664	0.9799957275390625	0.8445326782205574	yfinance
1350	2026-02-19	EQ.XLY	116.23999786376953	-0.779998779296875	-0.6665517019933114	yfinance
1351	2026-02-20	EQ.XLY	117.44999694824219	1.2099990844726562	1.0409489906312162	yfinance
1352	2026-02-23	EQ.XLY	114.98999786376953	-2.4599990844726562	-2.0945075763235037	yfinance
1353	2026-02-24	EQ.XLY	116.73999786376953	1.75	1.5218714953567116	yfinance
1354	2026-02-25	EQ.XLY	117.08999633789062	0.34999847412109375	0.29981024543920815	yfinance
1355	2026-02-26	EQ.XLY	117.05000305175781	-0.0399932861328125	-0.034156023045216005	yfinance
1356	2026-02-27	EQ.XLY	116.86000061035156	-0.19000244140625	-0.16232587479919472	yfinance
1357	2026-03-02	EQ.XLY	115.41999816894531	-1.44000244140625	-1.2322457931586672	yfinance
1358	2026-03-03	EQ.XLY	114.36000061035156	-1.05999755859375	-0.9183829279239678	yfinance
1359	2026-03-04	EQ.XLY	116.38999938964844	2.029998779296875	1.775095110582856	yfinance
1360	2026-03-05	EQ.XLY	116.55000305175781	0.160003662109375	0.13747200184589528	yfinance
1361	2026-03-06	EQ.XLY	114.44000244140625	-2.1100006103515625	-1.810382286660729	yfinance
1362	2026-02-09	EQ.XLP	87.43000030517578	\N	\N	yfinance
1363	2026-02-10	EQ.XLP	87.1500015258789	-0.279998779296875	-0.320254807639866	yfinance
1364	2026-02-11	EQ.XLP	88.4000015258789	1.25	1.4343086381115169	yfinance
1365	2026-02-12	EQ.XLP	89.20999908447266	0.80999755859375	0.9162868151723108	yfinance
1366	2026-02-13	EQ.XLP	89.51000213623047	0.3000030517578125	0.33628859414485657	yfinance
1367	2026-02-17	EQ.XLP	88.19999694824219	-1.3100051879882812	-1.4635293897038548	yfinance
1368	2026-02-18	EQ.XLP	88.04000091552734	-0.15999603271484375	-0.1814014039124436	yfinance
1369	2026-02-19	EQ.XLP	87.66999816894531	-0.37000274658203125	-0.4202666319109215	yfinance
1370	2026-02-20	EQ.XLP	87.88999938964844	0.220001220703125	0.2509424264834243	yfinance
1371	2026-02-23	EQ.XLP	88.97000122070312	1.0800018310546875	1.228810830077089	yfinance
1372	2026-02-24	EQ.XLP	89.73999786376953	0.7699966430664062	0.8654564825241676	yfinance
1373	2026-02-25	EQ.XLP	89.01000213623047	-0.7299957275390625	-0.8134563683043964	yfinance
1374	2026-02-26	EQ.XLP	88.86000061035156	-0.15000152587890625	-0.16852210120086034	yfinance
1375	2026-02-27	EQ.XLP	90.01000213623047	1.1500015258789062	1.2941723137293555	yfinance
1376	2026-03-02	EQ.XLP	88.70999908447266	-1.3000030517578125	-1.4442873246356034	yfinance
1377	2026-03-03	EQ.XLP	87.73999786376953	-0.970001220703125	-1.0934519566159133	yfinance
1378	2026-03-04	EQ.XLP	87.16000366210938	-0.5799942016601562	-0.6610374011641653	yfinance
1379	2026-03-05	EQ.XLP	85.41000366210938	-1.75	-2.007801659559554	yfinance
1380	2026-03-06	EQ.XLP	85.77999877929688	0.3699951171875	0.4331988073097832	yfinance
1381	2026-02-09	EQ.XLI	173.6999969482422	\N	\N	yfinance
1382	2026-02-10	EQ.XLI	173.91000366210938	0.2100067138671875	0.12090196750536715	yfinance
1383	2026-02-11	EQ.XLI	174.83999633789062	0.92999267578125	0.5347551355286827	yfinance
1384	2026-02-12	EQ.XLI	172.75	-2.089996337890625	-1.195376562380818	yfinance
1385	2026-02-13	EQ.XLI	174.1699981689453	1.4199981689453125	0.8219960456991678	yfinance
1386	2026-02-17	EQ.XLI	175.0800018310547	0.910003662109375	0.522480146796964	yfinance
1387	2026-02-18	EQ.XLI	175.0399932861328	-0.040008544921875	-0.02285157899443117	yfinance
1388	2026-02-19	EQ.XLI	176.33999633789062	1.3000030517578125	0.7426891576902286	yfinance
1389	2026-02-20	EQ.XLI	177.22999572753906	0.8899993896484375	0.5047064807368384	yfinance
1390	2026-02-23	EQ.XLI	174.8300018310547	-2.399993896484375	-1.3541691329575818	yfinance
1391	2026-02-24	EQ.XLI	176.97999572753906	2.149993896484375	1.229762554462478	yfinance
1392	2026-02-25	EQ.XLI	175.60000610351562	-1.3799896240234375	-0.7797432802224344	yfinance
1393	2026-02-26	EQ.XLI	176.6999969482422	1.0999908447265625	0.6264184547226732	yfinance
1394	2026-02-27	EQ.XLI	177.13999938964844	0.44000244140625	0.24901100679426308	yfinance
1395	2026-03-02	EQ.XLI	178.89999389648438	1.7599945068359375	0.9935613147229053	yfinance
1396	2026-03-03	EQ.XLI	175.44000244140625	-3.459991455078125	-1.9340366535060673	yfinance
1397	2026-03-04	EQ.XLI	175.97000122070312	0.529998779296875	0.30209688322016803	yfinance
1398	2026-03-05	EQ.XLI	172.05999755859375	-3.910003662109375	-2.221971719603169	yfinance
1399	2026-03-06	EQ.XLI	169.94000244140625	-2.1199951171875	-1.2321255069561137	yfinance
1400	2026-02-09	EQ.XLB	52.18000030517578	\N	\N	yfinance
1401	2026-02-10	EQ.XLB	52.90999984741211	0.7299995422363281	1.3990025641374302	yfinance
1402	2026-02-11	EQ.XLB	53.619998931884766	0.7099990844726562	1.341899615422855	yfinance
1403	2026-02-12	EQ.XLB	52.83000183105469	-0.7899971008300781	-1.4733254691661544	yfinance
1404	2026-02-13	EQ.XLB	53.310001373291016	0.4799995422363281	0.9085737755060485	yfinance
1405	2026-02-17	EQ.XLB	52.70000076293945	-0.6100006103515625	-1.1442517250753261	yfinance
1406	2026-02-18	EQ.XLB	53.02000045776367	0.31999969482421875	0.6072100383141817	yfinance
1407	2026-02-19	EQ.XLB	52.83000183105469	-0.18999862670898438	-0.3583527443767931	yfinance
1408	2026-02-20	EQ.XLB	52.959999084472656	0.12999725341796875	0.24606709996658258	yfinance
1409	2026-02-23	EQ.XLB	52.959999084472656	0	0	yfinance
1410	2026-02-24	EQ.XLB	53.36000061035156	0.40000152587890625	0.7552899033115404	yfinance
1411	2026-02-25	EQ.XLB	53.060001373291016	-0.2999992370605469	-0.5622174543272936	yfinance
1412	2026-02-26	EQ.XLB	53	-0.060001373291015625	-0.11308211786292699	yfinance
1413	2026-02-27	EQ.XLB	53.40999984741211	0.4099998474121094	0.7735846177586969	yfinance
1414	2026-03-02	EQ.XLB	53.25	-0.15999984741210938	-0.299569084196247	yfinance
1415	2026-03-03	EQ.XLB	51.939998626708984	-1.3100013732910156	-2.460096475663879	yfinance
1416	2026-03-04	EQ.XLB	51.91999816894531	-0.020000457763671875	-0.038506850774899876	yfinance
1417	2026-03-05	EQ.XLB	50.83000183105469	-1.089996337890625	-2.099376687849307	yfinance
1418	2026-03-06	EQ.XLB	49.86000061035156	-0.970001220703125	-1.9083241899678645	yfinance
1419	2026-02-09	FX.AUDUSD	0.7033699154853821	\N	\N	yfinance
1420	2026-02-10	FX.AUDUSD	0.7083597779273987	0.0049898624420166016	0.7094222161283644	yfinance
1421	2026-02-11	FX.AUDUSD	0.7074797749519348	-0.0008800029754638672	-0.1242310761967149	yfinance
1422	2026-02-12	FX.AUDUSD	0.7125298380851746	0.005050063133239746	0.7138102475908714	yfinance
1423	2026-02-13	FX.AUDUSD	0.7087101936340332	-0.0038196444511413574	-0.536067999819646	yfinance
1424	2026-02-16	FX.AUDUSD	0.7070400714874268	-0.0016701221466064453	-0.2356565718411086	yfinance
1425	2026-02-17	FX.AUDUSD	0.7072985768318176	0.00025850534439086914	0.03656162568651049	yfinance
1426	2026-02-18	FX.AUDUSD	0.708320140838623	0.00102156400680542	0.14443179164608	yfinance
1427	2026-02-19	FX.AUDUSD	0.704379141330719	-0.003940999507904053	-0.5563867636515412	yfinance
1428	2026-02-20	FX.AUDUSD	0.7056102752685547	0.0012311339378356934	0.17478284997335736	yfinance
1429	2026-02-23	FX.AUDUSD	0.7111399173736572	0.005529642105102539	0.7836680245335093	yfinance
1430	2026-02-24	FX.AUDUSD	0.706070065498352	-0.005069851875305176	-0.7129190404651835	yfinance
1431	2026-02-25	FX.AUDUSD	0.7060999870300293	2.9921531677246094e-05	0.004237756724062101	yfinance
1432	2026-02-26	FX.AUDUSD	0.7120498418807983	0.005949854850769043	0.8426363064804879	yfinance
1433	2026-02-27	FX.AUDUSD	0.71017986536026	-0.00186997652053833	-0.2626187677535326	yfinance
1434	2026-03-02	FX.AUDUSD	0.7058109045028687	-0.004368960857391357	-0.6151907524405907	yfinance
1435	2026-03-03	FX.AUDUSD	0.710580050945282	0.00476914644241333	0.6756974725082256	yfinance
1436	2026-03-04	FX.AUDUSD	0.7040701508522034	-0.006509900093078613	-0.9161388761784851	yfinance
1437	2026-03-05	FX.AUDUSD	0.7075998783111572	0.0035297274589538574	0.5013317855729988	yfinance
1438	2026-03-06	FX.AUDUSD	0.7011299729347229	-0.006469905376434326	-0.9143451793513842	yfinance
1439	2026-02-09	FX.EURGBP	0.868910014629364	\N	\N	yfinance
1440	2026-02-10	FX.EURGBP	0.8699100017547607	0.0009999871253967285	0.11508523420843249	yfinance
1441	2026-02-11	FX.EURGBP	0.871940016746521	0.002030014991760254	0.2333591966600405	yfinance
1442	2026-02-12	FX.EURGBP	0.8716599941253662	-0.00028002262115478516	-0.032114895035972375	yfinance
1443	2026-02-13	FX.EURGBP	0.8714399933815002	-0.0002200007438659668	-0.025239284279269705	yfinance
1444	2026-02-16	FX.EURGBP	0.8694999814033508	-0.001940011978149414	-0.22262140742720227	yfinance
1445	2026-02-17	FX.EURGBP	0.8695200085639954	2.002716064453125e-05	0.0023032962706000205	yfinance
1446	2026-02-18	FX.EURGBP	0.8736799955368042	0.004159986972808838	0.47842337517672767	yfinance
1447	2026-02-19	FX.EURGBP	0.873449981212616	-0.00023001432418823242	-0.026327067732265935	yfinance
1448	2026-02-20	FX.EURGBP	0.8742499947547913	0.000800013542175293	0.09159237041423131	yfinance
1449	2026-02-23	FX.EURGBP	0.874459981918335	0.00020998716354370117	0.024019120938353355	yfinance
1450	2026-02-24	FX.EURGBP	0.8737800121307373	-0.0006799697875976562	-0.07775882277722779	yfinance
1451	2026-02-25	FX.EURGBP	0.8723400235176086	-0.0014399886131286621	-0.16479990308054873	yfinance
1452	2026-02-26	FX.EURGBP	0.871399998664856	-0.0009400248527526855	-0.10775899619533055	yfinance
1453	2026-02-27	FX.EURGBP	0.8747699856758118	0.0033699870109558105	0.38673250127602093	yfinance
1454	2026-03-02	FX.EURGBP	0.8770700097084045	0.0023000240325927734	0.26292900651087936	yfinance
1455	2026-03-03	FX.EURGBP	0.8721299767494202	-0.004940032958984375	-0.5632427177195085	yfinance
1456	2026-03-04	FX.EURGBP	0.8695999979972839	-0.0025299787521362305	-0.29009193808082373	yfinance
1457	2026-03-05	FX.EURGBP	0.8702200055122375	0.0006200075149536133	0.07129801246337512	yfinance
1458	2026-03-06	FX.EURGBP	0.8689900040626526	-0.001230001449584961	-0.14134373397459937	yfinance
1459	2026-02-09	CM.SILVER	82.06500244140625	\N	\N	yfinance
1460	2026-02-10	CM.SILVER	80.21800231933594	-1.8470001220703125	-2.250655050414524	yfinance
1461	2026-02-11	CM.SILVER	83.75399780273438	3.5359954833984375	4.40798247421092	yfinance
1462	2026-02-12	CM.SILVER	75.5459976196289	-8.208000183105469	-9.800129424792063	yfinance
1463	2026-02-13	CM.SILVER	77.85099792480469	2.3050003051757812	3.051121671304635	yfinance
1464	2026-02-17	CM.SILVER	73.4469985961914	-4.403999328613281	-5.656959378821385	yfinance
1465	2026-02-18	CM.SILVER	77.50900268554688	4.062004089355469	5.530524278722676	yfinance
1466	2026-02-19	CM.SILVER	77.56500244140625	0.055999755859375	0.07224935674448729	yfinance
1467	2026-02-20	CM.SILVER	82.28299713134766	4.717994689941406	6.082633328743139	yfinance
1468	2026-02-23	CM.SILVER	86.52300262451172	4.2400054931640625	5.152954609074069	yfinance
1469	2026-02-24	CM.SILVER	87.45700073242188	0.9339981079101562	1.0794795367464018	yfinance
1470	2026-02-25	CM.SILVER	90.93900299072266	3.4820022583007812	3.981387686680571	yfinance
1471	2026-02-26	CM.SILVER	86.99800109863281	-3.9410018920898438	-4.333676159273369	yfinance
1472	2026-02-27	CM.SILVER	92.68199920654297	5.683998107910156	6.5334812709846055	yfinance
1473	2026-03-02	CM.SILVER	88.28399658203125	-4.398002624511719	-4.745260851258416	yfinance
1474	2026-03-03	CM.SILVER	82.9229965209961	-5.361000061035156	-6.072448312932742	yfinance
1475	2026-03-04	CM.SILVER	82.63300323486328	-0.2899932861328125	-0.34971394944632306	yfinance
1476	2026-03-05	CM.SILVER	81.68699645996094	-0.9460067749023438	-1.1448292302938092	yfinance
1477	2026-03-06	CM.SILVER	83.81600189208984	2.1290054321289062	2.6062966254028486	yfinance
1478	2026-02-09	EQ.MOVE	62.7400016784668	\N	\N	yfinance
1479	2026-02-10	EQ.MOVE	64.55000305175781	1.8100013732910156	2.8849240115851513	yfinance
1480	2026-02-11	EQ.MOVE	61.349998474121094	-3.2000045776367188	-4.957404223623158	yfinance
1481	2026-02-12	EQ.MOVE	68.56999969482422	7.220001220703125	11.768543439734062	yfinance
1482	2026-02-13	EQ.MOVE	70.0999984741211	1.529998779296875	2.231294715044839	yfinance
1483	2026-02-17	EQ.MOVE	68.83999633789062	-1.2600021362304688	-1.7974353261870974	yfinance
1484	2026-02-18	EQ.MOVE	64.19000244140625	-4.649993896484375	-6.754785217681577	yfinance
1485	2026-02-19	EQ.MOVE	68.02999877929688	3.839996337890625	5.9822342916965	yfinance
1486	2026-02-20	EQ.MOVE	64.2699966430664	-3.7600021362304688	-5.526976633394745	yfinance
1487	2026-02-23	EQ.MOVE	68.02999877929688	3.7600021362304688	5.850322596268731	yfinance
1488	2026-02-24	EQ.MOVE	65.2699966430664	-2.7600021362304688	-4.057036874547765	yfinance
1489	2026-02-25	EQ.MOVE	62.43000030517578	-2.839996337890625	-4.3511513466460645	yfinance
1490	2026-02-26	EQ.MOVE	63.93000030517578	1.5	2.4026910021905636	yfinance
1491	2026-02-27	EQ.MOVE	73.37999725341797	9.449996948242188	14.781787741485612	yfinance
1492	2026-03-02	EQ.MOVE	73.20999908447266	-0.1699981689453125	-0.2316682683405172	yfinance
1493	2026-03-03	EQ.MOVE	77.75	4.540000915527344	6.201339943043719	yfinance
1494	2026-03-04	EQ.MOVE	70.02999877929688	-7.720001220703125	-9.929262020196946	yfinance
1495	2026-03-05	EQ.MOVE	74.52999877929688	4.5	6.42581761879217	yfinance
1496	2026-03-06	EQ.MOVE	81.26000213623047	6.730003356933594	9.029925489282405	yfinance
2168	2026-01-20	EQ.XLE	47.599998474121094	-0.09000015258789062	-0.18871913436685583	yfinance
2169	2026-01-21	EQ.XLE	48.75	1.1500015258789062	2.4159696696295754	yfinance
2170	2026-01-22	EQ.XLE	48.90999984741211	0.15999984741210938	0.3282048152043269	yfinance
2171	2026-01-23	EQ.XLE	49.189998626708984	0.279998779296875	0.5724775713972735	yfinance
2172	2026-01-26	EQ.XLE	49.220001220703125	0.030002593994140625	0.06099328081267711	yfinance
2173	2026-01-27	EQ.XLE	49.66999816894531	0.4499969482421875	0.914256272006974	yfinance
2174	2026-01-28	EQ.XLE	50.04999923706055	0.3800010681152344	0.765051504175047	yfinance
2175	2026-01-29	EQ.XLE	50.5099983215332	0.45999908447265625	0.9190791038654812	yfinance
2176	2026-01-30	EQ.XLE	51.04999923706055	0.5400009155273438	1.0690970767606083	yfinance
2177	2026-02-02	EQ.XLE	50.04999923706055	-1	-1.9588638882369156	yfinance
2178	2026-02-03	EQ.XLE	51.66999816894531	1.6199989318847656	3.23676115200658	yfinance
2179	2026-02-04	EQ.XLE	52.83000183105469	1.160003662109375	2.2450236176059324	yfinance
2180	2026-02-05	EQ.XLE	52.209999084472656	-0.6200027465820312	-1.1735807781433378	yfinance
2181	2026-02-06	EQ.XLE	53.25	1.0400009155273438	1.9919573525459835	yfinance
2182	2025-12-09	EQ.XLF	53.09443283081055	\N	\N	yfinance
2183	2025-12-10	EQ.XLF	53.702308654785156	0.6078758239746094	1.144895597456803	yfinance
2184	2025-12-11	EQ.XLF	54.67889404296875	0.9765853881835938	1.818516582706682	yfinance
2185	2025-12-12	EQ.XLF	54.75861740112305	0.07972335815429688	0.14580279932444726	yfinance
2186	2025-12-15	EQ.XLF	54.79847717285156	0.039859771728515625	0.07279177893870296	yfinance
2187	2025-12-16	EQ.XLF	54.4496955871582	-0.3487815856933594	-0.636480434653673	yfinance
2188	2025-12-17	EQ.XLF	54.43973159790039	-0.0099639892578125	-0.01829943978633092	yfinance
2189	2025-12-18	EQ.XLF	54.35004425048828	-0.08968734741210938	-0.1647461234279274	yfinance
2190	2025-12-19	EQ.XLF	54.64899826049805	0.2989540100097656	0.5500529284427949	yfinance
2191	2025-12-22	EQ.XLF	55.31999969482422	0.6710014343261719	1.2278384886904543	yfinance
2192	2025-12-23	EQ.XLF	55.43000030517578	0.1100006103515625	0.19884419912940499	yfinance
2193	2025-12-24	EQ.XLF	55.72999954223633	0.2999992370605469	0.5412217849699965	yfinance
2194	2025-12-26	EQ.XLF	55.619998931884766	-0.1100006103515625	-0.19738132290526197	yfinance
2195	2025-12-29	EQ.XLF	55.31999969482422	-0.2999992370605469	-0.5393729644402583	yfinance
2196	2025-12-30	EQ.XLF	55.18000030517578	-0.1399993896484375	-0.2530719277309323	yfinance
2197	2025-12-31	EQ.XLF	54.77000045776367	-0.4099998474121094	-0.7430225537234224	yfinance
2198	2026-01-02	EQ.XLF	54.93000030517578	0.15999984741210938	0.29213044746182637	yfinance
2199	2026-01-05	EQ.XLF	56.130001068115234	1.2000007629394531	2.1845999568042656	yfinance
2200	2026-01-06	EQ.XLF	56.400001525878906	0.2700004577636719	0.48102699559192813	yfinance
2201	2026-01-07	EQ.XLF	55.61000061035156	-0.7900009155273438	-1.400710805237931	yfinance
2202	2026-01-08	EQ.XLF	55.900001525878906	0.29000091552734375	0.5214905814501309	yfinance
2203	2026-01-09	EQ.XLF	55.72999954223633	-0.17000198364257812	-0.3041180304152151	yfinance
2204	2026-01-12	EQ.XLF	55.290000915527344	-0.4399986267089844	-0.7895184466590939	yfinance
2205	2026-01-13	EQ.XLF	54.22999954223633	-1.0600013732910156	-1.9171664961816461	yfinance
2206	2026-01-14	EQ.XLF	54.150001525878906	-0.07999801635742188	-0.14751616638889414	yfinance
2207	2026-01-15	EQ.XLF	54.369998931884766	0.21999740600585938	0.4062740531978011	yfinance
2208	2026-01-16	EQ.XLF	54.439998626708984	0.06999969482421875	0.12874691226666202	yfinance
2209	2026-01-20	EQ.XLF	53.20000076293945	-1.2399978637695312	-2.277733091567662	yfinance
2210	2026-01-21	EQ.XLF	53.459999084472656	0.2599983215332031	0.4887186424898041	yfinance
2211	2026-01-22	EQ.XLF	53.810001373291016	0.3500022888183594	0.654699391717754	yfinance
2212	2026-01-23	EQ.XLF	53.06999969482422	-0.7400016784667969	-1.375212153096324	yfinance
2213	2026-01-26	EQ.XLF	53.40999984741211	0.3400001525878906	0.6406635661259481	yfinance
2214	2026-01-27	EQ.XLF	53	-0.4099998474121094	-0.7676462246460298	yfinance
2215	2026-01-28	EQ.XLF	52.9900016784668	-0.009998321533203125	-0.018864757609817217	yfinance
2216	2026-01-29	EQ.XLF	53.54999923706055	0.55999755859375	1.0567985296390594	yfinance
2217	2026-01-30	EQ.XLF	53.439998626708984	-0.1100006103515625	-0.20541664223859404	yfinance
2218	2026-02-02	EQ.XLF	54.029998779296875	0.5900001525878906	1.1040422300703656	yfinance
2219	2026-02-03	EQ.XLF	53.529998779296875	-0.5	-0.9254118291625599	yfinance
2220	2026-02-04	EQ.XLF	53.959999084472656	0.43000030517578125	0.8032884643780098	yfinance
2298	2026-01-29	EQ.EEM	60.439998626708984	-0.3100013732910156	-0.510290326404964	yfinance
2299	2026-01-30	EQ.EEM	59.099998474121094	-1.3400001525878906	-2.217075087747822	yfinance
2300	2026-02-02	EQ.EEM	59.279998779296875	0.18000030517578125	0.3045690521542067	yfinance
2301	2026-02-03	EQ.EEM	59.599998474121094	0.31999969482421875	0.5398105624387705	yfinance
2302	2026-02-04	EQ.EEM	58.79999923706055	-0.7999992370605469	-1.3422806334599395	yfinance
2303	2026-02-05	EQ.EEM	58.529998779296875	-0.2700004577636719	-0.45918445793702595	yfinance
2304	2026-02-06	EQ.EEM	60.06999969482422	1.5400009155273438	2.631130954460348	yfinance
2305	2025-12-09	EQ.GLD	387.3999938964844	\N	\N	yfinance
2306	2025-12-10	EQ.GLD	389.04998779296875	1.649993896484375	0.42591479671661103	yfinance
2307	2025-12-11	EQ.GLD	393.239990234375	4.19000244140625	1.0769830543307821	yfinance
2308	2025-12-12	EQ.GLD	395.44000244140625	2.20001220703125	0.5594579039939505	yfinance
2309	2025-12-15	EQ.GLD	395.79998779296875	0.3599853515625	0.09103412637567954	yfinance
2310	2025-12-16	EQ.GLD	395.8900146484375	0.09002685546875	0.02274554276030963	yfinance
2311	2025-12-17	EQ.GLD	399.2900085449219	3.399993896484375	0.858822847427378	yfinance
2312	2025-12-18	EQ.GLD	398.57000732421875	-0.720001220703125	-0.18032036998043785	yfinance
2313	2025-12-19	EQ.GLD	399.0199890136719	0.449981689453125	0.11289903434381733	yfinance
2314	2025-12-22	EQ.GLD	408.2300109863281	9.21002197265625	2.3081605499068574	yfinance
2315	2025-12-23	EQ.GLD	413.6400146484375	5.410003662109375	1.3252341857567544	yfinance
2316	2025-12-24	EQ.GLD	411.92999267578125	-1.71002197265625	-0.41340825647867707	yfinance
2317	2025-12-26	EQ.GLD	416.739990234375	4.80999755859375	1.1676735474757156	yfinance
2318	2025-12-29	EQ.GLD	398.6000061035156	-18.139984130859375	-4.352830195311333	yfinance
2319	2025-12-30	EQ.GLD	398.8900146484375	0.290008544921875	0.07275678386381167	yfinance
2320	2025-12-31	EQ.GLD	396.30999755859375	-2.58001708984375	-0.6467991163222406	yfinance
2321	2026-01-02	EQ.GLD	398.2799987792969	1.970001220703125	0.4970859258759587	yfinance
2322	2026-01-05	EQ.GLD	408.760009765625	10.480010986328125	2.631317419516094	yfinance
2323	2026-01-06	EQ.GLD	413.17999267578125	4.41998291015625	1.0813149047262676	yfinance
2324	2026-01-07	EQ.GLD	409.2300109863281	-3.949981689453125	-0.9559953917111957	yfinance
2325	2026-01-08	EQ.GLD	411.489990234375	2.259979248046875	0.5522515913727496	yfinance
2326	2026-01-09	EQ.GLD	414.4700012207031	2.980010986328125	0.7242001159325361	yfinance
2327	2026-01-12	EQ.GLD	422.2300109863281	7.760009765625	1.872272961316888	yfinance
2328	2026-01-13	EQ.GLD	421.6300048828125	-0.600006103515625	-0.14210408732292915	yfinance
2329	2026-01-14	EQ.GLD	425.94000244140625	4.30999755859375	1.0222226854541976	yfinance
2330	2026-01-15	EQ.GLD	423.3299865722656	-2.610015869140625	-0.6127660830587678	yfinance
2331	2026-01-16	EQ.GLD	421.2900085449219	-2.03997802734375	-0.48188838307004983	yfinance
2332	2026-01-20	EQ.GLD	437.2300109863281	15.94000244140625	3.7836174886892855	yfinance
2333	2026-01-21	EQ.GLD	443.6000061035156	6.3699951171875	1.4568979615140565	yfinance
2334	2026-01-22	EQ.GLD	451.7900085449219	8.19000244140625	1.846258414950311	yfinance
2335	2026-01-23	EQ.GLD	458	6.209991455078125	1.3745304981574553	yfinance
2336	2026-01-26	EQ.GLD	464.70001220703125	6.70001220703125	1.462884761360535	yfinance
2337	2026-01-27	EQ.GLD	476.1000061035156	11.399993896484375	2.4531942321975873	yfinance
2338	2026-01-28	EQ.GLD	494.55999755859375	18.459991455078125	3.8773348494905244	yfinance
2339	2026-01-29	EQ.GLD	495.8999938964844	1.339996337890625	0.27094717415592573	yfinance
2340	2026-01-30	EQ.GLD	444.95001220703125	-50.949981689453125	-10.27424527456005	yfinance
2341	2026-02-02	EQ.GLD	427.1300048828125	-17.82000732421875	-4.004945911975222	yfinance
2342	2026-02-03	EQ.GLD	454.2900085449219	27.160003662109375	6.358720612372105	yfinance
2343	2026-02-04	EQ.GLD	453.9700012207031	-0.32000732421875	-0.07044119795716496	yfinance
2344	2026-02-05	EQ.GLD	441.8800048828125	-12.089996337890625	-2.663170761367759	yfinance
2345	2026-02-06	EQ.GLD	455.4599914550781	13.579986572265625	3.073229479090611	yfinance
2346	2025-12-09	EQ.SLV	55.16999816894531	\N	\N	yfinance
2347	2025-12-10	EQ.SLV	56.06999969482422	0.9000015258789062	1.631324190229009	yfinance
2348	2025-12-11	EQ.SLV	57.619998931884766	1.5499992370605469	2.764400295161097	yfinance
2349	2025-12-12	EQ.SLV	56.099998474121094	-1.5200004577636719	-2.6379737694208116	yfinance
2350	2025-12-15	EQ.SLV	58.11000061035156	2.0100021362304688	3.5828916058842353	yfinance
2351	2025-12-16	EQ.SLV	57.72999954223633	-0.3800010681152344	-0.6539340287797931	yfinance
2352	2025-12-17	EQ.SLV	60.2599983215332	2.529998779296875	4.382468039768269	yfinance
2353	2025-12-18	EQ.SLV	59.31999969482422	-0.9399986267089844	-1.559904833872335	yfinance
2354	2025-12-19	EQ.SLV	60.93000030517578	1.6100006103515625	2.7140940974954826	yfinance
2355	2025-12-22	EQ.SLV	62.470001220703125	1.5400009155273438	2.5274920528705893	yfinance
2356	2025-12-23	EQ.SLV	64.83999633789062	2.3699951171875	3.7938131437110685	yfinance
2357	2025-12-24	EQ.SLV	65.22000122070312	0.3800048828125	0.5860655525522233	yfinance
2358	2025-12-26	EQ.SLV	71.12000274658203	5.900001525878906	9.046306984744486	yfinance
2359	2025-12-29	EQ.SLV	66.01000213623047	-5.1100006103515625	-7.1850399507994185	yfinance
2360	2025-12-30	EQ.SLV	68.9800033569336	2.970001220703125	4.499319988770308	yfinance
2361	2025-12-31	EQ.SLV	64.41999816894531	-4.560005187988281	-6.6106189708237055	yfinance
2362	2026-01-02	EQ.SLV	65.75	1.3300018310546875	2.064579119618535	yfinance
2363	2026-01-05	EQ.SLV	69.08000183105469	3.3300018310546875	5.064641568144012	yfinance
2364	2026-01-06	EQ.SLV	73.70999908447266	4.629997253417969	6.702369905463101	yfinance
2365	2026-01-07	EQ.SLV	70.95999908447266	-2.75	-3.730837110509882	yfinance
2366	2026-01-08	EQ.SLV	69.70999908447266	-1.25	-1.7615558288155655	yfinance
2367	2026-01-09	EQ.SLV	72.37999725341797	2.6699981689453125	3.8301509166710535	yfinance
2368	2026-01-12	EQ.SLV	77.2300033569336	4.850006103515625	6.7007547493193576	yfinance
2369	2026-01-13	EQ.SLV	78.5999984741211	1.3699951171875	1.7739156514804215	yfinance
2370	2026-01-14	EQ.SLV	84.55999755859375	5.959999084472656	7.5826961834292845	yfinance
2371	2026-01-15	EQ.SLV	83.31999969482422	-1.2399978637695312	-1.466411896370155	yfinance
2372	2026-01-16	EQ.SLV	81.0199966430664	-2.3000030517578125	-2.7604453434733833	yfinance
2373	2026-01-20	EQ.SLV	85.38999938964844	4.370002746582031	5.3937335567095595	yfinance
2374	2026-01-21	EQ.SLV	83.95999908447266	-1.4300003051757812	-1.6746695343683722	yfinance
2375	2026-01-22	EQ.SLV	87.12999725341797	3.1699981689453125	3.7756052924154493	yfinance
2376	2026-01-23	EQ.SLV	92.91000366210938	5.780006408691406	6.633773201989475	yfinance
2377	2026-01-26	EQ.SLV	98.33999633789062	5.42999267578125	5.84435740152243	yfinance
2378	2026-01-27	EQ.SLV	101.58999633789062	3.25	3.304860810481612	yfinance
2379	2026-01-28	EQ.SLV	105.5999984741211	4.010002136230469	3.947241146552571	yfinance
2380	2026-01-29	EQ.SLV	105.56999969482422	-0.029998779296875	-0.02840793535070615	yfinance
2381	2026-01-30	EQ.SLV	75.44000244140625	-30.12999725341797	-28.540302491726873	yfinance
2382	2026-02-02	EQ.SLV	72.44000244140625	-3	-3.976670072790732	yfinance
2383	2026-02-03	EQ.SLV	76.95999908447266	4.519996643066406	6.239641759706519	yfinance
2384	2026-02-04	EQ.SLV	79.18000030517578	2.220001220703125	2.884617005083917	yfinance
2385	2026-02-05	EQ.SLV	66.69000244140625	-12.489997863769531	-15.774182641614734	yfinance
2386	2026-02-06	EQ.SLV	70.19000244140625	3.5	5.248162950773762	yfinance
2387	2025-12-09	EQ.XLK	147.7958221435547	\N	\N	yfinance
2388	2025-12-10	EQ.XLK	148.50474548339844	0.70892333984375	0.47966399155394923	yfinance
2389	2025-12-11	EQ.XLK	147.7458953857422	-0.75885009765625	-0.5109938373929491	yfinance
2390	2025-12-12	EQ.XLK	143.47238159179688	-4.2735137939453125	-2.892475478109097	yfinance
2391	2025-12-15	EQ.XLK	142.08448791503906	-1.3878936767578125	-0.9673594745967236	yfinance
2392	2025-12-16	EQ.XLK	142.34408569335938	0.2595977783203125	0.1827066290836349	yfinance
2393	2025-12-17	EQ.XLK	139.17889404296875	-3.165191650390625	-2.223620064699525	yfinance
2394	2025-12-18	EQ.XLK	141.3256378173828	2.1467437744140625	1.5424348563592534	yfinance
5867	2024-03-19	EQ.ASML	935.7936	\N	\N	yfinance_direct
2395	2025-12-19	EQ.XLK	144.38101196289062	3.0553741455078125	2.161939045664089	yfinance
2396	2025-12-22	EQ.XLK	145.16000366210938	0.77899169921875	0.539538883006977	yfinance
2397	2025-12-23	EQ.XLK	145.9499969482422	0.7899932861328125	0.5442224209167761	yfinance
2398	2025-12-24	EQ.XLK	146.3000030517578	0.350006103515625	0.2398123404139204	yfinance
2399	2025-12-26	EQ.XLK	146.52999877929688	0.2299957275390625	0.15720828622108432	yfinance
2400	2025-12-29	EQ.XLK	145.8699951171875	-0.660003662109375	-0.4504222122484768	yfinance
2401	2025-12-30	EQ.XLK	145.41000366210938	-0.459991455078125	-0.31534343626225664	yfinance
2402	2025-12-31	EQ.XLK	143.97000122070312	-1.44000244140625	-0.9903049344200537	yfinance
2403	2026-01-02	EQ.XLK	144.3000030517578	0.3300018310546875	0.22921568955799432	yfinance
2404	2026-01-05	EQ.XLK	144.6199951171875	0.3199920654296875	0.2217547184076719	yfinance
2405	2026-01-06	EQ.XLK	146.64999389648438	2.029998779296875	1.4036778093180962	yfinance
2406	2026-01-07	EQ.XLK	146.52999877929688	-0.1199951171875	-0.08182415423228778	yfinance
2407	2026-01-08	EQ.XLK	144.24000549316406	-2.2899932861328125	-1.5628153314748845	yfinance
2408	2026-01-09	EQ.XLK	146.14999389648438	1.9099884033203125	1.324173828744642	yfinance
2409	2026-01-12	EQ.XLK	146.7899932861328	0.6399993896484375	0.43790586135893955	yfinance
2410	2026-01-13	EQ.XLK	146.47999572753906	-0.30999755859375	-0.21118439455847796	yfinance
2411	2026-01-14	EQ.XLK	144.6999969482422	-1.779998779296875	-1.2151821622167247	yfinance
2412	2026-01-15	EQ.XLK	145.4600067138672	0.760009765625	0.5252313625803657	yfinance
2413	2026-01-16	EQ.XLK	145.6199951171875	0.1599884033203125	0.10998789765974916	yfinance
2414	2026-01-20	EQ.XLK	141.83999633789062	-3.779998779296875	-2.5957965293536276	yfinance
2415	2026-01-21	EQ.XLK	143.80999755859375	1.970001220703125	1.3888897853678708	yfinance
2416	2026-01-22	EQ.XLK	144.8800048828125	1.07000732421875	0.7440423770140095	yfinance
2417	2026-01-23	EQ.XLK	145.08999633789062	0.209991455078125	0.14494163997853154	yfinance
2418	2026-01-26	EQ.XLK	146.0800018310547	0.9900054931640625	0.6823389056117303	yfinance
2419	2026-01-27	EQ.XLK	148.0500030517578	1.970001220703125	1.3485769414087785	yfinance
2420	2026-01-28	EQ.XLK	149.22999572753906	1.17999267578125	0.7970230675164041	yfinance
2421	2026-01-29	EQ.XLK	146.8699951171875	-2.3600006103515625	-1.581451905058284	yfinance
2422	2026-01-30	EQ.XLK	143.8800048828125	-2.989990234375	-2.0358074036764884	yfinance
2423	2026-02-02	EQ.XLK	145.25999450683594	1.3799896240234375	0.9591253664103032	yfinance
2424	2026-02-03	EQ.XLK	142.0800018310547	-3.17999267578125	-2.189173066250942	yfinance
2425	2026-02-04	EQ.XLK	138.1199951171875	-3.9600067138671875	-2.7871668516558548	yfinance
2426	2026-02-05	EQ.XLK	135.6300048828125	-2.489990234375	-1.802773184478015	yfinance
2427	2026-02-06	EQ.XLK	141.1300048828125	5.5	4.055149894562143	yfinance
2428	2025-12-09	EQ.XLV	149.32412719726562	\N	\N	yfinance
2429	2025-12-10	EQ.XLV	151.494873046875	2.170745849609375	1.4537140717666455	yfinance
2430	2025-12-11	EQ.XLV	152.92877197265625	1.43389892578125	0.9464999685748957	yfinance
2431	2025-12-12	EQ.XLV	153.40673828125	0.47796630859375	0.3125417816597721	yfinance
2432	2025-12-15	EQ.XLV	155.43809509277344	2.0313568115234375	1.3241640062767166	yfinance
2433	2025-12-16	EQ.XLV	153.4167022705078	-2.021392822265625	-1.3004487870615977	yfinance
2434	2025-12-17	EQ.XLV	153.13787841796875	-0.2788238525390625	-0.1817428274839554	yfinance
2435	2025-12-18	EQ.XLV	153.2573699951172	0.1194915771484375	0.07802875316210252	yfinance
2436	2025-12-19	EQ.XLV	154.2830047607422	1.025634765625	0.669223780662344	yfinance
2437	2025-12-22	EQ.XLV	155.3000030517578	1.016998291015625	0.65917713528639	yfinance
2438	2025-12-23	EQ.XLV	154.99000549316406	-0.30999755859375	-0.19961207501743264	yfinance
2439	2025-12-24	EQ.XLV	155.8000030517578	0.80999755859375	0.5226127684920144	yfinance
2440	2025-12-26	EQ.XLV	156.0500030517578	0.25	0.16046212779402086	yfinance
2441	2025-12-29	EQ.XLV	155.80999755859375	-0.2400054931640625	-0.15380037710377922	yfinance
2442	2025-12-30	EQ.XLV	155.67999267578125	-0.1300048828125	-0.08343808795941383	yfinance
2443	2025-12-31	EQ.XLV	154.8000030517578	-0.8799896240234375	-0.5652554377081078	yfinance
2444	2026-01-02	EQ.XLV	155.50999450683594	0.709991455078125	0.45865080173205	yfinance
2445	2026-01-05	EQ.XLV	155.0399932861328	-0.470001220703125	-0.30223216340121767	yfinance
2446	2026-01-06	EQ.XLV	158.08999633789062	3.0500030517578125	1.9672363156833372	yfinance
2447	2026-01-07	EQ.XLV	159.66000366210938	1.57000732421875	0.9931098491919279	yfinance
2448	2026-01-08	EQ.XLV	158.1199951171875	-1.540008544921875	-0.9645549978697332	yfinance
2449	2026-01-09	EQ.XLV	157.30999755859375	-0.80999755859375	-0.5122676344591564	yfinance
2450	2026-01-12	EQ.XLV	157.3800048828125	0.07000732421875	0.04450278132683471	yfinance
2451	2026-01-13	EQ.XLV	156.74000549316406	-0.6399993896484375	-0.40665864137251145	yfinance
2452	2026-01-14	EQ.XLV	157.86000061035156	1.1199951171875	0.7145560022558163	yfinance
2453	2026-01-15	EQ.XLV	156.9600067138672	-0.899993896484375	-0.5701215589792406	yfinance
2454	2026-01-16	EQ.XLV	155.74000549316406	-1.220001220703125	-0.7772688382507184	yfinance
2455	2026-01-20	EQ.XLV	155.39999389648438	-0.3400115966796875	-0.21832001071465978	yfinance
2456	2026-01-21	EQ.XLV	158.25999450683594	2.8600006103515625	1.840412305457796	yfinance
2457	2026-01-22	EQ.XLV	158.2899932861328	0.029998779296875	0.018955377440998976	yfinance
2458	2026-01-23	EQ.XLV	157.47999572753906	-0.80999755859375	-0.5117174761196422	yfinance
2459	2026-01-26	EQ.XLV	158.10000610351562	0.6200103759765625	0.39370738684122225	yfinance
2460	2026-01-27	EQ.XLV	155.4499969482422	-2.6500091552734375	-1.676160058803761	yfinance
2461	2026-01-28	EQ.XLV	154.30999755859375	-1.1399993896484375	-0.7333543982172002	yfinance
2462	2026-01-29	EQ.XLV	153.82000732421875	-0.489990234375	-0.3175362854820496	yfinance
2463	2026-01-30	EQ.XLV	154.74000549316406	0.9199981689453125	0.5981004584183633	yfinance
2464	2026-02-02	EQ.XLV	155.69000244140625	0.9499969482421875	0.6139310550070747	yfinance
2465	2026-02-03	EQ.XLV	154.10000610351562	-1.589996337890625	-1.0212578283496516	yfinance
2466	2026-02-04	EQ.XLV	156.02999877929688	1.92999267578125	1.2524286822446915	yfinance
2467	2026-02-05	EQ.XLV	154.83999633789062	-1.19000244140625	-0.7626754154433459	yfinance
2468	2026-02-06	EQ.XLV	157.7100067138672	2.8700103759765625	1.8535329655482866	yfinance
2469	2025-12-09	EQ.XLY	117.74665832519531	\N	\N	yfinance
2470	2025-12-10	EQ.XLY	119.47322845458984	1.7265701293945312	1.466343210034931	yfinance
2471	2025-12-11	EQ.XLY	119.94229888916016	0.4690704345703125	0.3926155178342735	yfinance
2472	2025-12-12	EQ.XLY	120.46126556396484	0.5189666748046875	0.4326802801105802	yfinance
2473	2025-12-15	EQ.XLY	121.4892349243164	1.0279693603515625	0.8533609169212252	yfinance
2474	2025-12-16	EQ.XLY	121.6888427734375	0.19960784912109375	0.1643008528660523	yfinance
2475	2025-12-17	EQ.XLY	120.28162384033203	-1.4072189331054688	-1.1564075235109719	yfinance
2476	2025-12-18	EQ.XLY	122.0980224609375	1.8163986206054688	1.510121465450657	yfinance
2477	2025-12-19	EQ.XLY	121.60899353027344	-0.4890289306640625	-0.40052158160097656	yfinance
2478	2025-12-22	EQ.XLY	122.33999633789062	0.7310028076171875	0.6011091666795277	yfinance
2479	2025-12-23	EQ.XLY	122.16999816894531	-0.1699981689453125	-0.1389555125339344	yfinance
2480	2025-12-24	EQ.XLY	122.58999633789062	0.4199981689453125	0.3437817592208762	yfinance
2481	2025-12-26	EQ.XLY	122.05000305175781	-0.5399932861328125	-0.4404872357157491	yfinance
2482	2025-12-29	EQ.XLY	120.8499984741211	-1.2000045776367188	-0.983207331119715	yfinance
2483	2025-12-30	EQ.XLY	120.36000061035156	-0.48999786376953125	-0.40545955312896403	yfinance
2484	2025-12-31	EQ.XLY	119.41000366210938	-0.9499969482421875	-0.7892962308281037	yfinance
2485	2026-01-02	EQ.XLY	118.3499984741211	-1.0600051879882812	-0.8877021652120065	yfinance
2486	2026-01-05	EQ.XLY	120.30000305175781	1.9500045776367188	1.6476591489463475	yfinance
2487	2026-01-06	EQ.XLY	121.06999969482422	0.7699966430664062	0.6400636937100685	yfinance
2488	2026-01-07	EQ.XLY	120.9000015258789	-0.1699981689453125	-0.14041312412143334	yfinance
2489	2026-01-08	EQ.XLY	122.91999816894531	2.0199966430664062	1.6707995182564341	yfinance
2490	2026-01-09	EQ.XLY	124.41000366210938	1.4900054931640625	1.2121750043602748	yfinance
2491	2026-01-12	EQ.XLY	124.5199966430664	0.10999298095703125	0.08841168533019744	yfinance
2492	2026-01-13	EQ.XLY	124.20999908447266	-0.30999755859375	-0.24895403706309965	yfinance
2493	2026-01-14	EQ.XLY	122.25	-1.9599990844726562	-1.577972062570986	yfinance
2494	2026-01-15	EQ.XLY	122.69999694824219	0.4499969482421875	0.36809566318379344	yfinance
2495	2026-01-16	EQ.XLY	122.30000305175781	-0.399993896484375	-0.325993403775798	yfinance
2496	2026-01-20	EQ.XLY	119.12000274658203	-3.1800003051757812	-2.6001637169461014	yfinance
2497	2026-01-21	EQ.XLY	121.4000015258789	2.279998779296875	1.9140351970503091	yfinance
2498	2026-01-22	EQ.XLY	122.62000274658203	1.220001220703125	1.0049433322643382	yfinance
2499	2026-01-23	EQ.XLY	123.12999725341797	0.5099945068359375	0.41591461051419143	yfinance
2500	2026-01-26	EQ.XLY	122.31999969482422	-0.80999755859375	-0.6578393378233144	yfinance
2501	2026-01-27	EQ.XLY	122.69000244140625	0.37000274658203125	0.3024875306615026	yfinance
2502	2026-01-28	EQ.XLY	121.7699966430664	-0.9200057983398438	-0.7498620751753722	yfinance
2503	2026-01-29	EQ.XLY	121.19000244140625	-0.5799942016601562	-0.47630304479702157	yfinance
2504	2026-01-30	EQ.XLY	121.16999816894531	-0.0200042724609375	-0.016506536890787918	yfinance
2505	2026-02-02	EQ.XLY	121.97000122070312	0.8000030517578125	0.6602319582792942	yfinance
2506	2026-02-03	EQ.XLY	120.98999786376953	-0.9800033569335938	-0.8034790088755435	yfinance
2507	2026-02-04	EQ.XLY	120.0999984741211	-0.8899993896484375	-0.7355974918278331	yfinance
2508	2026-02-05	EQ.XLY	117.51000213623047	-2.589996337890625	-2.156533197998926	yfinance
2509	2026-02-06	EQ.XLY	117.98999786376953	0.4799957275390625	0.4084722311404597	yfinance
2510	2025-12-09	EQ.XLP	77.3692855834961	\N	\N	yfinance
2511	2025-12-10	EQ.XLP	77.59745788574219	0.22817230224609375	0.2949132857118768	yfinance
2512	2025-12-11	EQ.XLP	78.17284393310547	0.5753860473632812	0.7415011561467699	yfinance
2513	2025-12-12	EQ.XLP	78.78790283203125	0.6150588989257812	0.786793556407009	yfinance
2514	2025-12-15	EQ.XLP	79.00615692138672	0.21825408935546875	0.2770147211822187	yfinance
2515	2025-12-16	EQ.XLP	78.64901733398438	-0.35713958740234375	-0.45204019701617354	yfinance
2516	2025-12-17	EQ.XLP	79.01607513427734	0.36705780029296875	0.466703606396316	yfinance
2517	2025-12-18	EQ.XLP	78.55973815917969	-0.45633697509765625	-0.5775242244342965	yfinance
2518	2025-12-19	EQ.XLP	78.15299987792969	-0.40673828125	-0.5177439370098929	yfinance
2519	2025-12-22	EQ.XLP	77.87999725341797	-0.27300262451171875	-0.3493181642907278	yfinance
2520	2025-12-23	EQ.XLP	77.51000213623047	-0.3699951171875	-0.4750836289625855	yfinance
2521	2025-12-24	EQ.XLP	78.12000274658203	0.6100006103515625	0.7869959921810273	yfinance
2522	2025-12-26	EQ.XLP	78.2300033569336	0.1100006103515625	0.14080978812609596	yfinance
2523	2025-12-29	EQ.XLP	78.27999877929688	0.04999542236328125	0.06390824519739728	yfinance
2524	2025-12-30	EQ.XLP	78.1500015258789	-0.12999725341796875	-0.16606701002191354	yfinance
2525	2025-12-31	EQ.XLP	77.68000030517578	-0.470001220703125	-0.6014090998417791	yfinance
2526	2026-01-02	EQ.XLP	77.69000244140625	0.01000213623046875	0.012876076456197327	yfinance
2527	2026-01-05	EQ.XLP	77.3499984741211	-0.34000396728515625	-0.4376418542933977	yfinance
2528	2026-01-06	EQ.XLP	77.47000122070312	0.12000274658203125	0.15514253257830438	yfinance
2529	2026-01-07	EQ.XLP	76.62000274658203	-0.8499984741210938	-1.097196928782208	yfinance
2530	2026-01-08	EQ.XLP	78.44000244140625	1.8199996948242188	2.375358430674825	yfinance
2531	2026-01-09	EQ.XLP	79.25	0.80999755859375	1.032633265404101	yfinance
2532	2026-01-12	EQ.XLP	80.18000030517578	0.9300003051757812	1.1735019623669165	yfinance
2533	2026-01-13	EQ.XLP	81.11000061035156	0.9300003051757812	1.1598906231430233	yfinance
2534	2026-01-14	EQ.XLP	82.2300033569336	1.1200027465820312	1.3808442092886537	yfinance
2535	2026-01-15	EQ.XLP	82.37000274658203	0.1399993896484375	0.17025341594690915	yfinance
2536	2026-01-16	EQ.XLP	82.11000061035156	-0.26000213623046875	-0.31565148423071726	yfinance
2537	2026-01-20	EQ.XLP	82.36000061035156	0.25	0.3044696116693033	yfinance
2538	2026-01-21	EQ.XLP	82.44000244140625	0.0800018310546875	0.09713675383901385	yfinance
2539	2026-01-22	EQ.XLP	82.2699966430664	-0.17000579833984375	-0.20621760468854228	yfinance
2540	2026-01-23	EQ.XLP	82.91000366210938	0.6400070190429688	0.777934903558681	yfinance
2541	2026-01-26	EQ.XLP	82.77999877929688	-0.1300048828125	-0.15680240872056964	yfinance
2542	2026-01-27	EQ.XLP	83.16000366210938	0.3800048828125	0.4590539845568813	yfinance
2543	2026-01-28	EQ.XLP	82.31999969482422	-0.8400039672851562	-1.0101057362842465	yfinance
2544	2026-01-29	EQ.XLP	82.12999725341797	-0.19000244140625	-0.23080957496431598	yfinance
2545	2026-01-30	EQ.XLP	83.51000213623047	1.3800048828125	1.6802689991019926	yfinance
2546	2026-02-02	EQ.XLP	84.5	0.9899978637695312	1.1854841796729219	yfinance
2547	2026-02-03	EQ.XLP	85.87000274658203	1.3700027465820312	1.6213050255408654	yfinance
2548	2026-02-04	EQ.XLP	86.98999786376953	1.1199951171875	1.3042914654292128	yfinance
2549	2026-02-05	EQ.XLP	86.91999816894531	-0.06999969482421875	-0.08046867058652145	yfinance
2550	2026-02-06	EQ.XLP	87.94000244140625	1.0200042724609375	1.173497807119563	yfinance
2551	2025-12-09	EQ.XLI	152.7368621826172	\N	\N	yfinance
2552	2025-12-10	EQ.XLI	155.52731323242188	2.7904510498046875	1.8269663327693173	yfinance
2553	2025-12-11	EQ.XLI	157.19161987304688	1.664306640625	1.0701056978576107	yfinance
2554	2025-12-12	EQ.XLI	156.2050018310547	-0.9866180419921875	-0.6276530789548531	yfinance
2555	2025-12-15	EQ.XLI	156.4541473388672	0.2491455078125	0.15949905885982205	yfinance
2556	2025-12-16	EQ.XLI	155.52731323242188	-0.9268341064453125	-0.5923998322894336	yfinance
2557	2025-12-17	EQ.XLI	153.00595092773438	-2.5213623046875	-1.621170103362839	yfinance
2558	2025-12-18	EQ.XLI	154.00253295898438	0.99658203125	0.651335471076345	yfinance
2559	2025-12-19	EQ.XLI	155.3280029296875	1.325469970703125	0.860680629880379	yfinance
2560	2025-12-22	EQ.XLI	157.0500030517578	1.7220001220703125	1.1086218129320906	yfinance
2561	2025-12-23	EQ.XLI	156.99000549316406	-0.05999755859375	-0.03820283822215339	yfinance
2562	2025-12-24	EQ.XLI	157.5	0.5099945068359375	0.3248579457232674	yfinance
2563	2025-12-26	EQ.XLI	157.2100067138672	-0.2899932861328125	-0.18412272135416666	yfinance
2564	2025-12-29	EQ.XLI	156.8699951171875	-0.3400115966796875	-0.21627859688253276	yfinance
2565	2025-12-30	EQ.XLI	156.4199981689453	-0.4499969482421875	-0.2868597961681733	yfinance
2566	2025-12-31	EQ.XLI	155.1199951171875	-1.3000030517578125	-0.8310977285357796	yfinance
2567	2026-01-02	EQ.XLI	157.97999572753906	2.8600006103515625	1.8437343349520714	yfinance
2568	2026-01-05	EQ.XLI	159.85000610351562	1.8700103759765625	1.1837007384160743	yfinance
2569	2026-01-06	EQ.XLI	162.02000427246094	2.1699981689453125	1.3575214801931665	yfinance
2570	2026-01-07	EQ.XLI	158.97000122070312	-3.0500030517578125	-1.8824854779220812	yfinance
2571	2026-01-08	EQ.XLI	160.1699981689453	1.1999969482421875	0.7548574819322001	yfinance
2572	2026-01-09	EQ.XLI	161.92999267578125	1.7599945068359375	1.0988290734570136	yfinance
2573	2026-01-12	EQ.XLI	163.1699981689453	1.2400054931640625	0.7657664109494655	yfinance
2574	2026-01-13	EQ.XLI	164.00999450683594	0.839996337890625	0.5147982762253251	yfinance
2575	2026-01-14	EQ.XLI	164.27000427246094	0.260009765625	0.15853287868634297	yfinance
2576	2026-01-15	EQ.XLI	165.77999877929688	1.5099945068359375	0.9192149921244512	yfinance
2577	2026-01-16	EQ.XLI	166.89999389648438	1.1199951171875	0.6755912205540253	yfinance
2578	2026-01-20	EQ.XLI	163.52999877929688	-3.3699951171875	-2.019170305828565	yfinance
2579	2026-01-21	EQ.XLI	166.36000061035156	2.8300018310546875	1.730570447122739	yfinance
2580	2026-01-22	EQ.XLI	165.5	-0.8600006103515625	-0.5169515551793343	yfinance
2581	2026-01-23	EQ.XLI	164.22000122070312	-1.279998779296875	-0.773413159695997	yfinance
2582	2026-01-26	EQ.XLI	164.3800048828125	0.160003662109375	0.09743250573621566	yfinance
2583	2026-01-27	EQ.XLI	165.05999755859375	0.67999267578125	0.4136711616878348	yfinance
2584	2026-01-28	EQ.XLI	164.13999938964844	-0.9199981689453125	-0.5573719753744255	yfinance
2585	2026-01-29	EQ.XLI	165.86000061035156	1.720001220703125	1.0478866986102826	yfinance
2586	2026-01-30	EQ.XLI	165.44000244140625	-0.4199981689453125	-0.25322450705399296	yfinance
2587	2026-02-02	EQ.XLI	167.52999877929688	2.089996337890625	1.2632956401405018	yfinance
2588	2026-02-03	EQ.XLI	168.94000244140625	1.410003662109375	0.8416424953043223	yfinance
2589	2026-02-04	EQ.XLI	169.38999938964844	0.4499969482421875	0.26636494716416304	yfinance
2590	2026-02-05	EQ.XLI	168.3699951171875	-1.0200042724609375	-0.602163218688382	yfinance
2591	2026-02-06	EQ.XLI	173.17999267578125	4.80999755859375	2.856802101375566	yfinance
2592	2025-12-09	EQ.XLB	43.16716766357422	\N	\N	yfinance
2593	2025-12-10	EQ.XLB	44.0128059387207	0.8456382751464844	1.9589848510261652	yfinance
2594	2025-12-11	EQ.XLB	44.888282775878906	0.8754768371582031	1.9891411567286459	yfinance
2595	2025-12-12	EQ.XLB	44.91813278198242	0.029850006103515625	0.0664984362457184	yfinance
2596	2025-12-15	EQ.XLB	44.888282775878906	-0.029850006103515625	-0.06645424521183363	yfinance
2597	2025-12-16	EQ.XLB	44.76890182495117	-0.11938095092773438	-0.26595125396929803	yfinance
2598	2025-12-17	EQ.XLB	44.957923889160156	0.18902206420898438	0.4222173350333025	yfinance
2599	2025-12-18	EQ.XLB	44.938026428222656	-0.0198974609375	-0.04425796214824211	yfinance
2600	2025-12-19	EQ.XLB	45.137001037597656	0.198974609375	0.4427755849332025	yfinance
2601	2025-12-22	EQ.XLB	45.66999816894531	0.5329971313476562	1.1808430314271143	yfinance
2602	2025-12-23	EQ.XLB	45.75	0.0800018310546875	0.17517371198207568	yfinance
2603	2025-12-24	EQ.XLB	45.84000015258789	0.09000015258789062	0.19672164500085382	yfinance
2604	2025-12-26	EQ.XLB	46.11000061035156	0.2700004577636719	0.5890062322533152	yfinance
2605	2025-12-29	EQ.XLB	45.7400016784668	-0.3699989318847656	-0.8024266471202387	yfinance
2606	2025-12-30	EQ.XLB	45.72999954223633	-0.01000213623046875	-0.021867371804617786	yfinance
2607	2025-12-31	EQ.XLB	45.349998474121094	-0.3800010681152344	-0.8309667000198951	yfinance
2608	2026-01-02	EQ.XLB	46.119998931884766	0.7700004577636719	1.6979062484490963	yfinance
2609	2026-01-05	EQ.XLB	46.58000183105469	0.4600028991699219	0.9974044011781228	yfinance
2610	2026-01-06	EQ.XLB	47.5	0.9199981689453125	1.9750925993565627	yfinance
2611	2026-01-07	EQ.XLB	46.68000030517578	-0.8199996948242188	-1.7263151469983553	yfinance
2612	2026-01-08	EQ.XLB	47.5	0.8199996948242188	1.7566402944802442	yfinance
2613	2026-01-09	EQ.XLB	48.2599983215332	0.7599983215332031	1.5999964663856907	yfinance
2614	2026-01-12	EQ.XLB	48.52000045776367	0.26000213623046875	0.538752891158842	yfinance
2615	2026-01-13	EQ.XLB	48.72999954223633	0.20999908447265625	0.43280932088089946	yfinance
2616	2026-01-14	EQ.XLB	48.75	0.020000457763671875	0.04104341873908011	yfinance
2617	2026-01-15	EQ.XLB	48.959999084472656	0.20999908447265625	0.4307673527644231	yfinance
2618	2026-01-16	EQ.XLB	48.68000030517578	-0.279998779296875	-0.5718929422645246	yfinance
2619	2026-01-20	EQ.XLB	48.189998626708984	-0.4900016784667969	-1.0065769831449625	yfinance
2620	2026-01-21	EQ.XLB	49.2400016784668	1.0500030517578125	2.1788816801830233	yfinance
2621	2026-01-22	EQ.XLB	49.52000045776367	0.279998779296875	0.5686408808944489	yfinance
2622	2026-01-23	EQ.XLB	49.970001220703125	0.4500007629394531	0.9087252802496747	yfinance
2623	2026-01-26	EQ.XLB	50.029998779296875	0.05999755859375	0.12006715454890232	yfinance
2624	2026-01-27	EQ.XLB	49.97999954223633	-0.049999237060546875	-0.0999385134529271	yfinance
2625	2026-01-28	EQ.XLB	49.95000076293945	-0.029998779296875	-0.060021567770372014	yfinance
2626	2026-01-29	EQ.XLB	50	0.049999237060546875	0.10009857116487564	yfinance
2627	2026-01-30	EQ.XLB	49.27000045776367	-0.7299995422363281	-1.4599990844726562	yfinance
2628	2026-02-02	EQ.XLB	49.650001525878906	0.3800010681152344	0.7712625625830618	yfinance
2629	2026-02-03	EQ.XLB	50.70000076293945	1.0499992370605469	2.1148020237486986	yfinance
2630	2026-02-04	EQ.XLB	51.88999938964844	1.1899986267089844	2.3471372954669585	yfinance
2631	2026-02-05	EQ.XLB	50.5	-1.3899993896484375	-2.678742351123884	yfinance
2632	2026-02-06	EQ.XLB	51.5099983215332	1.0099983215332031	1.9999966763033725	yfinance
2633	2025-12-09	FX.AUDUSD	0.6627300977706909	\N	\N	yfinance
2634	2025-12-10	FX.AUDUSD	0.6640987992286682	0.001368701457977295	0.2065247168615654	yfinance
2635	2025-12-11	FX.AUDUSD	0.6674498319625854	0.0033510327339172363	0.5045985232633103	yfinance
2636	2025-12-12	FX.AUDUSD	0.6665000319480896	-0.0009498000144958496	-0.14230283221482504	yfinance
2637	2025-12-15	FX.AUDUSD	0.6647300720214844	-0.0017699599266052246	-0.26556036635615315	yfinance
2638	2025-12-16	FX.AUDUSD	0.6641799807548523	-0.0005500912666320801	-0.08275408166193222	yfinance
2639	2025-12-17	FX.AUDUSD	0.6634001135826111	-0.0007798671722412109	-0.11741804854685294	yfinance
2640	2025-12-18	FX.AUDUSD	0.6601501107215881	-0.0032500028610229492	-0.4899008599006272	yfinance
2641	2025-12-19	FX.AUDUSD	0.6613800525665283	0.0012299418449401855	0.18631244999652838	yfinance
2642	2025-12-22	FX.AUDUSD	0.6610198020935059	-0.00036025047302246094	-0.05446950987174251	yfinance
2643	2025-12-23	FX.AUDUSD	0.6658400893211365	0.004820287227630615	0.7292197922610422	yfinance
2644	2025-12-24	FX.AUDUSD	0.6701900959014893	0.004350006580352783	0.6533110051676031	yfinance
2645	2025-12-26	FX.AUDUSD	0.6705604195594788	0.00037032365798950195	0.05525651009380711	yfinance
2646	2025-12-29	FX.AUDUSD	0.6714099645614624	0.0008495450019836426	0.12669179050886226	yfinance
2647	2025-12-30	FX.AUDUSD	0.6695501804351807	-0.0018597841262817383	-0.2769968014246666	yfinance
2648	2025-12-31	FX.AUDUSD	0.6697999835014343	0.0002498030662536621	0.03730908803449208	yfinance
2649	2026-01-02	FX.AUDUSD	0.6678299903869629	-0.0019699931144714355	-0.29411662630583163	yfinance
2650	2026-01-05	FX.AUDUSD	0.6683902144432068	0.0005602240562438965	0.08388722643607006	yfinance
2651	2026-01-06	FX.AUDUSD	0.6713401079177856	0.0029498934745788574	0.4413430075478028	yfinance
2652	2026-01-07	FX.AUDUSD	0.6737000942230225	0.0023599863052368164	0.3515336380775015	yfinance
2653	2026-01-08	FX.AUDUSD	0.672210156917572	-0.0014899373054504395	-0.22115735447072818	yfinance
2654	2026-01-09	FX.AUDUSD	0.6701065301895142	-0.0021036267280578613	-0.31294182428067846	yfinance
2655	2026-01-12	FX.AUDUSD	0.6685801148414612	-0.0015264153480529785	-0.22778696808420745	yfinance
2656	2026-01-13	FX.AUDUSD	0.6707807779312134	0.0022006630897521973	0.3291547326791248	yfinance
2657	2026-01-14	FX.AUDUSD	0.6683598756790161	-0.0024209022521972656	-0.36090811362598735	yfinance
2658	2026-01-15	FX.AUDUSD	0.6682798862457275	-7.998943328857422e-05	-0.011968018458216009	yfinance
2659	2026-01-16	FX.AUDUSD	0.6704210042953491	0.002141118049621582	0.32039241247405875	yfinance
2660	2026-01-19	FX.AUDUSD	0.6687598824501038	-0.0016611218452453613	-0.24777294186826612	yfinance
2661	2026-01-20	FX.AUDUSD	0.6709878444671631	0.002227962017059326	0.33314827571547023	yfinance
2662	2026-01-21	FX.AUDUSD	0.6731699109077454	0.0021820664405822754	0.3252020820608266	yfinance
2663	2026-01-22	FX.AUDUSD	0.6754794120788574	0.0023095011711120605	0.3430784908371471	yfinance
2664	2026-01-23	FX.AUDUSD	0.6840506792068481	0.008571267127990723	1.2689161171636254	yfinance
2665	2026-01-26	FX.AUDUSD	0.691399872303009	0.007349193096160889	1.0743638329081444	yfinance
2666	2026-01-27	FX.AUDUSD	0.691472053527832	7.218122482299805e-05	0.010439866669712706	yfinance
2667	2026-01-28	FX.AUDUSD	0.6995800137519836	0.008107960224151611	1.1725651358989106	yfinance
2668	2026-01-29	FX.AUDUSD	0.7039799094200134	0.004399895668029785	0.6289338719715976	yfinance
2669	2026-01-30	FX.AUDUSD	0.7047300934791565	0.0007501840591430664	0.10656327675048555	yfinance
2670	2026-02-02	FX.AUDUSD	0.6946277618408203	-0.010102331638336182	-1.4335036536416865	yfinance
2671	2026-02-03	FX.AUDUSD	0.6955500841140747	0.0009223222732543945	0.13277935664566085	yfinance
2672	2026-02-04	FX.AUDUSD	0.7022520899772644	0.006702005863189697	0.9635547484299527	yfinance
2673	2026-02-05	FX.AUDUSD	0.699440062046051	-0.002812027931213379	-0.4004299839541124	yfinance
2674	2026-02-06	FX.AUDUSD	0.6916399002075195	-0.007800161838531494	-1.1152008959443809	yfinance
2675	2025-12-09	FX.EURGBP	0.8734400272369385	\N	\N	yfinance
2676	2025-12-10	FX.EURGBP	0.8740299940109253	0.0005899667739868164	0.06754519550164557	yfinance
2677	2025-12-11	FX.EURGBP	0.8739100098609924	-0.00011998414993286133	-0.013727692499688008	yfinance
2678	2025-12-12	FX.EURGBP	0.876579999923706	0.002669990062713623	0.30552231151790127	yfinance
2679	2025-12-15	FX.EURGBP	0.8780199885368347	0.0014399886131286621	0.1642734962301208	yfinance
2680	2025-12-16	FX.EURGBP	0.8784499764442444	0.00042998790740966797	0.04897245085800562	yfinance
2681	2025-12-17	FX.EURGBP	0.8751400113105774	-0.003309965133666992	-0.3767960865643073	yfinance
2682	2025-12-18	FX.EURGBP	0.8779000043869019	0.002759993076324463	0.3153773157041693	yfinance
2683	2025-12-19	FX.EURGBP	0.8759599924087524	-0.001940011978149414	-0.2209832519028472	yfinance
2684	2025-12-22	FX.EURGBP	0.8751299977302551	-0.0008299946784973145	-0.09475257839287379	yfinance
2685	2025-12-23	FX.EURGBP	0.8734300136566162	-0.001699984073638916	-0.19425503388616658	yfinance
2686	2025-12-24	FX.EURGBP	0.8728100061416626	-0.0006200075149536133	-0.07098536863393906	yfinance
2687	2025-12-26	FX.EURGBP	0.8722699880599976	-0.0005400180816650391	-0.061871206547257515	yfinance
2688	2025-12-29	FX.EURGBP	0.872160017490387	-0.0001099705696105957	-0.012607400359512492	yfinance
2689	2025-12-30	FX.EURGBP	0.871399998664856	-0.0007600188255310059	-0.08714213106419808	yfinance
2690	2025-12-31	FX.EURGBP	0.8722400069236755	0.0008400082588195801	0.0963975510794843	yfinance
2691	2026-01-02	FX.EURGBP	0.8720499873161316	-0.0001900196075439453	-0.021785243285747703	yfinance
2692	2026-01-05	FX.EURGBP	0.8709700107574463	-0.0010799765586853027	-0.1238434234726724	yfinance
2693	2026-01-06	FX.EURGBP	0.8655700087547302	-0.0054000020027160645	-0.6199986148799668	yfinance
2694	2026-01-07	FX.EURGBP	0.8657100200653076	0.00014001131057739258	0.016175619437048504	yfinance
2695	2026-01-08	FX.EURGBP	0.8675699830055237	0.0018599629402160645	0.21484826294095016	yfinance
2696	2026-01-09	FX.EURGBP	0.867579996585846	1.0013580322265625e-05	0.0011542100946802664	yfinance
2697	2026-01-12	FX.EURGBP	0.8677800297737122	0.00020003318786621094	0.023056454580948595	yfinance
2698	2026-01-13	FX.EURGBP	0.8663899898529053	-0.0013900399208068848	-0.1601834420146037	yfinance
2699	2026-01-14	FX.EURGBP	0.867110013961792	0.0007200241088867188	0.08310623591218588	yfinance
2700	2026-01-15	FX.EURGBP	0.8664100170135498	-0.0006999969482421875	-0.0807275820796866	yfinance
2701	2026-01-16	FX.EURGBP	0.8675000071525574	0.0010899901390075684	0.12580534823046974	yfinance
2702	2026-01-19	FX.EURGBP	0.8672299981117249	-0.00027000904083251953	-0.031124961222626955	yfinance
2703	2026-01-20	FX.EURGBP	0.86735999584198	0.00012999773025512695	0.01498999464250306	yfinance
2704	2026-01-21	FX.EURGBP	0.8725000023841858	0.0051400065422058105	0.5926035979116384	yfinance
2705	2026-01-22	FX.EURGBP	0.8698099851608276	-0.0026900172233581543	-0.30831142876876066	yfinance
2706	2026-01-23	FX.EURGBP	0.8705899715423584	0.0007799863815307617	0.0896731924026536	yfinance
2707	2026-01-26	FX.EURGBP	0.8678799867630005	-0.00270998477935791	-0.3112814146660609	yfinance
2708	2026-01-27	FX.EURGBP	0.8682000041007996	0.00032001733779907227	0.03687345516430974	yfinance
2709	2026-01-28	FX.EURGBP	0.8692600131034851	0.0010600090026855469	0.12209272030393563	yfinance
2710	2026-01-29	FX.EURGBP	0.8662999868392944	-0.002960026264190674	-0.34052253866166093	yfinance
2711	2026-01-30	FX.EURGBP	0.8666599988937378	0.0003600120544433594	0.04155743505859529	yfinance
2712	2026-02-02	FX.EURGBP	0.8661999702453613	-0.00046002864837646484	-0.0530806370391706	yfinance
2713	2026-02-03	FX.EURGBP	0.8628699779510498	-0.0033299922943115234	-0.38443689779488954	yfinance
2714	2026-02-04	FX.EURGBP	0.8625800013542175	-0.0002899765968322754	-0.033606059341738465	yfinance
2715	2026-02-05	FX.EURGBP	0.8648999929428101	0.0023199915885925293	0.2689595846124686	yfinance
2716	2026-02-06	FX.EURGBP	0.8709999918937683	0.006099998950958252	0.7052837323079506	yfinance
2717	2025-12-09	EQ.SPX	6840.509765625	\N	\N	yfinance
2718	2025-12-10	EQ.SPX	6886.68017578125	46.17041015625	0.6749556939201523	yfinance
2719	2025-12-11	EQ.SPX	6901	14.31982421875	0.20793508415142145	yfinance
2720	2025-12-12	EQ.SPX	6827.41015625	-73.58984375	-1.0663649289957977	yfinance
2721	2025-12-15	EQ.SPX	6816.509765625	-10.900390625	-0.15965630269072792	yfinance
2722	2025-12-16	EQ.SPX	6800.259765625	-16.25	-0.2383917951962334	yfinance
2723	2025-12-17	EQ.SPX	6721.43017578125	-78.82958984375	-1.1592143912241404	yfinance
2724	2025-12-18	EQ.SPX	6774.759765625	53.32958984375	0.7934262269941882	yfinance
2725	2025-12-19	EQ.SPX	6834.5	59.740234375	0.8818059450332216	yfinance
2726	2025-12-22	EQ.SPX	6878.490234375	43.990234375	0.6436496360377496	yfinance
2727	2025-12-23	EQ.SPX	6909.7900390625	31.2998046875	0.45503887657033204	yfinance
2728	2025-12-24	EQ.SPX	6932.0498046875	22.259765625	0.32214822012189737	yfinance
2729	2025-12-26	EQ.SPX	6929.93994140625	-2.10986328125	-0.0304363549122699	yfinance
2730	2025-12-29	EQ.SPX	6905.740234375	-24.19970703125	-0.3492051480368141	yfinance
2731	2025-12-30	EQ.SPX	6896.240234375	-9.5	-0.13756671519023322	yfinance
2732	2025-12-31	EQ.SPX	6845.5	-50.740234375	-0.7357666300846107	yfinance
2733	2026-01-02	EQ.SPX	6858.47021484375	12.97021484375	0.18947067188298883	yfinance
2734	2026-01-05	EQ.SPX	6902.0498046875	43.57958984375	0.6354126864826347	yfinance
2735	2026-01-06	EQ.SPX	6944.81982421875	42.77001953125	0.6196712678341282	yfinance
2736	2026-01-07	EQ.SPX	6920.93017578125	-23.8896484375	-0.34399234310139126	yfinance
2737	2026-01-08	EQ.SPX	6921.4599609375	0.52978515625	0.00765482590915168	yfinance
2738	2026-01-09	EQ.SPX	6966.27978515625	44.81982421875	0.647548703188326	yfinance
2739	2026-01-12	EQ.SPX	6977.27001953125	10.990234375	0.1577633215137008	yfinance
2740	2026-01-13	EQ.SPX	6963.740234375	-13.52978515625	-0.19391230550597158	yfinance
2741	2026-01-14	EQ.SPX	6926.60009765625	-37.14013671875	-0.5333360445499638	yfinance
2742	2026-01-15	EQ.SPX	6944.47021484375	17.8701171875	0.2579926217127318	yfinance
2743	2026-01-16	EQ.SPX	6940.009765625	-4.46044921875	-0.06423023039562939	yfinance
2744	2026-01-20	EQ.SPX	6796.85986328125	-143.14990234375	-2.06267580562775	yfinance
2745	2026-01-21	EQ.SPX	6875.6201171875	78.76025390625	1.1587741323274499	yfinance
2746	2026-01-22	EQ.SPX	6913.35009765625	37.72998046875	0.5487502192628932	yfinance
2747	2026-01-23	EQ.SPX	6915.60986328125	2.259765625	0.032686983778907726	yfinance
2748	2026-01-26	EQ.SPX	6950.22998046875	34.6201171875	0.5006083031276405	yfinance
2749	2026-01-27	EQ.SPX	6978.60009765625	28.3701171875	0.40818961771372364	yfinance
2750	2026-01-28	EQ.SPX	6978.02978515625	-0.5703125	-0.008172305219087399	yfinance
2751	2026-01-29	EQ.SPX	6969.009765625	-9.02001953125	-0.12926312740076712	yfinance
2752	2026-01-30	EQ.SPX	6939.02978515625	-29.97998046875	-0.4301899620894176	yfinance
2753	2026-02-02	EQ.SPX	6976.43994140625	37.41015625	0.5391266129167885	yfinance
2754	2026-02-03	EQ.SPX	6917.81005859375	-58.6298828125	-0.8403983020698362	yfinance
2755	2026-02-04	EQ.SPX	6882.72021484375	-35.08984375	-0.5072391906223145	yfinance
2756	2026-02-05	EQ.SPX	6798.39990234375	-84.3203125	-1.225101556767468	yfinance
2757	2026-02-06	EQ.SPX	6932.2998046875	133.89990234375	1.9695796697335792	yfinance
2758	2025-12-09	EQ.SX7E	5718.31982421875	\N	\N	yfinance
2759	2025-12-10	EQ.SX7E	5708.1201171875	-10.19970703125	-0.17836895005507158	yfinance
2760	2025-12-11	EQ.SX7E	5753.9599609375	45.83984375	0.8030637549475075	yfinance
2761	2025-12-12	EQ.SX7E	5720.7099609375	-33.25	-0.5778629018228785	yfinance
2762	2025-12-15	EQ.SX7E	5752.52001953125	31.81005859375	0.5560508889798186	yfinance
2763	2025-12-16	EQ.SX7E	5717.830078125	-34.68994140625	-0.6030390383426557	yfinance
2764	2025-12-17	EQ.SX7E	5681.669921875	-36.16015625	-0.6324104731328024	yfinance
2765	2025-12-18	EQ.SX7E	5741.7099609375	60.0400390625	1.0567322616074513	yfinance
2766	2025-12-19	EQ.SX7E	5760.35009765625	18.64013671875	0.324644345422604	yfinance
2767	2025-12-22	EQ.SX7E	5743.68994140625	-16.66015625	-0.2892212446736288	yfinance
2768	2025-12-23	EQ.SX7E	5749.27978515625	5.58984375	0.09732147464477194	yfinance
2769	2025-12-29	EQ.SX7E	5751.7099609375	2.43017578125	0.04226922105137999	yfinance
2770	2025-12-30	EQ.SX7E	5796.22021484375	44.51025390625	0.7738612379368839	yfinance
2771	2026-01-05	EQ.SX7E	5923.68994140625	127.4697265625	2.199187088096794	yfinance
2772	2026-01-06	EQ.SX7E	5931.7900390625	8.10009765625	0.13674074329297328	yfinance
2773	2026-01-07	EQ.SX7E	5923.56982421875	-8.22021484375	-0.13857899200102466	yfinance
2774	2026-01-08	EQ.SX7E	5904.31982421875	-19.25	-0.3249729567007991	yfinance
2775	2026-01-09	EQ.SX7E	5997.47021484375	93.150390625	1.577665055387231	yfinance
2776	2026-01-12	EQ.SX7E	6016.2998046875	18.82958984375	0.3139588721449042	yfinance
2777	2026-01-13	EQ.SX7E	6029.830078125	13.5302734375	0.22489360365582367	yfinance
2778	2026-01-14	EQ.SX7E	6005.0498046875	-24.7802734375	-0.41096138890211525	yfinance
2779	2026-01-15	EQ.SX7E	6041.14013671875	36.09033203125	0.6009997119936981	yfinance
2780	2026-01-16	EQ.SX7E	6029.4501953125	-11.68994140625	-0.19350554931174632	yfinance
2781	2026-01-19	EQ.SX7E	5925.81982421875	-103.63037109375	-1.7187366631590353	yfinance
2782	2026-01-20	EQ.SX7E	5892.080078125	-33.73974609375	-0.5693684096815784	yfinance
2783	2026-01-21	EQ.SX7E	5882.8798828125	-9.2001953125	-0.15614511667376593	yfinance
2784	2026-01-22	EQ.SX7E	5956.169921875	73.2900390625	1.2458190634934627	yfinance
2785	2026-01-23	EQ.SX7E	5948.2001953125	-7.9697265625	-0.13380623231096694	yfinance
2786	2026-01-26	EQ.SX7E	5957.7998046875	9.599609375	0.16138679028599281	yfinance
2787	2026-01-27	EQ.SX7E	5994.58984375	36.7900390625	0.6175104949574538	yfinance
2788	2026-01-28	EQ.SX7E	5933.2001953125	-61.3896484375	-1.0240842165624602	yfinance
2789	2026-01-29	EQ.SX7E	5891.9501953125	-41.25	-0.6952403195932844	yfinance
2790	2026-01-30	EQ.SX7E	5947.81005859375	55.85986328125	0.9480708666833406	yfinance
2791	2026-02-02	EQ.SX7E	6007.509765625	59.69970703125	1.0037258493988441	yfinance
2792	2026-02-03	EQ.SX7E	5995.35009765625	-12.15966796875	-0.20240779363069336	yfinance
2793	2026-02-04	EQ.SX7E	5970.47021484375	-24.8798828125	-0.41498632118625134	yfinance
2794	2026-02-05	EQ.SX7E	5925.7001953125	-44.77001953125	-0.7498575140688756	yfinance
2795	2026-02-06	EQ.SX7E	5998.39990234375	72.69970703125	1.2268542895362609	yfinance
2796	2025-12-09	EQ.VIX	16.93000030517578	\N	\N	yfinance
2797	2025-12-10	EQ.VIX	15.770000457763672	-1.1599998474121094	-6.8517414441952385	yfinance
2798	2025-12-11	EQ.VIX	14.850000381469727	-0.9200000762939453	-5.83386207729007	yfinance
2799	2025-12-12	EQ.VIX	15.739999771118164	0.8899993896484375	5.993261729198373	yfinance
2800	2025-12-15	EQ.VIX	16.5	0.7600002288818359	4.828464040237059	yfinance
2801	2025-12-16	EQ.VIX	16.479999542236328	-0.020000457763671875	-0.1212148955374053	yfinance
2802	2025-12-17	EQ.VIX	17.6200008392334	1.1400012969970703	6.9174837904296	yfinance
2803	2025-12-18	EQ.VIX	16.8700008392334	-0.75	-4.256526471497209	yfinance
2804	2025-12-19	EQ.VIX	14.90999984741211	-1.960000991821289	-11.618262562637518	yfinance
2805	2025-12-22	EQ.VIX	14.079999923706055	-0.8299999237060547	-5.566733281020896	yfinance
2806	2025-12-23	EQ.VIX	14	-0.07999992370605469	-0.5681812794001605	yfinance
2807	2025-12-24	EQ.VIX	13.470000267028809	-0.5299997329711914	-3.7857123783656528	yfinance
2808	2025-12-26	EQ.VIX	13.600000381469727	0.13000011444091797	0.9651084770883467	yfinance
2809	2025-12-29	EQ.VIX	14.199999809265137	0.5999994277954102	4.411760374749117	yfinance
2810	2025-12-30	EQ.VIX	14.329999923706055	0.13000011444091797	0.9154937759653786	yfinance
2811	2025-12-31	EQ.VIX	14.949999809265137	0.619999885559082	4.326586802930954	yfinance
2812	2026-01-02	EQ.VIX	14.510000228881836	-0.4399995803833008	-2.943141043457504	yfinance
2813	2026-01-05	EQ.VIX	14.899999618530273	0.3899993896484375	2.687797267378069	yfinance
2814	2026-01-06	EQ.VIX	14.75	-0.14999961853027344	-1.0067088749702218	yfinance
2815	2026-01-07	EQ.VIX	15.380000114440918	0.630000114440918	4.271187216548596	yfinance
2816	2026-01-08	EQ.VIX	15.449999809265137	0.06999969482421875	0.4551345533378322	yfinance
2817	2026-01-09	EQ.VIX	14.489999771118164	-0.9600000381469727	-6.213592556624336	yfinance
2818	2026-01-12	EQ.VIX	15.119999885559082	0.630000114440918	4.3478269454265295	yfinance
2819	2026-01-13	EQ.VIX	15.979999542236328	0.8599996566772461	5.687828460227839	yfinance
2820	2026-01-14	EQ.VIX	16.75	0.7700004577636719	4.818526156577811	yfinance
2821	2026-01-15	EQ.VIX	15.84000015258789	-0.9099998474121094	-5.432834909923041	yfinance
2822	2026-01-16	EQ.VIX	15.859999656677246	0.01999950408935547	0.1262594942973407	yfinance
2823	2026-01-20	EQ.VIX	20.09000015258789	4.2300004959106445	26.67087381764075	yfinance
2824	2026-01-21	EQ.VIX	16.899999618530273	-3.190000534057617	-15.878549078292057	yfinance
2825	2026-01-22	EQ.VIX	15.640000343322754	-1.2599992752075195	-7.455617181351728	yfinance
2826	2026-01-23	EQ.VIX	16.09000015258789	0.4499998092651367	2.8772365689701336	yfinance
2827	2026-01-26	EQ.VIX	16.149999618530273	0.05999946594238281	0.3728991011397386	yfinance
2828	2026-01-27	EQ.VIX	16.350000381469727	0.20000076293945312	1.23839484621396	yfinance
2829	2026-01-28	EQ.VIX	16.350000381469727	0	0	yfinance
2830	2026-01-29	EQ.VIX	16.8799991607666	0.529998779296875	3.2415826723621923	yfinance
2831	2026-01-30	EQ.VIX	17.440000534057617	0.5600013732910156	3.3175438455743578	yfinance
2832	2026-02-02	EQ.VIX	16.34000015258789	-1.1000003814697266	-6.307341443720695	yfinance
2833	2026-02-03	EQ.VIX	18	1.6599998474121094	10.159117698350832	yfinance
2834	2026-02-04	EQ.VIX	18.639999389648438	0.6399993896484375	3.5555521647135415	yfinance
2835	2026-02-05	EQ.VIX	21.770000457763672	3.1300010681152344	16.791851773629634	yfinance
2836	2026-02-06	EQ.VIX	20.3700008392334	-1.3999996185302734	-6.430866279706494	yfinance
2837	2025-12-09	EQ.SPY	681.027587890625	\N	\N	yfinance
2838	2025-12-10	EQ.SPY	685.5443115234375	4.5167236328125	0.6632218302348566	yfinance
2839	2025-12-11	EQ.SPY	687.1395263671875	1.59521484375	0.23269317780568624	yfinance
2840	2025-12-12	EQ.SPY	679.7514038085938	-7.38812255859375	-1.0751997629438872	yfinance
2841	2025-12-15	EQ.SPY	678.7244262695312	-1.0269775390625	-0.1510813414004628	yfinance
2842	2025-12-16	EQ.SPY	676.8699340820312	-1.8544921875	-0.2732319798320555	yfinance
2843	2025-12-17	EQ.SPY	669.4219360351562	-7.447998046875	-1.1003588240296047	yfinance
2844	2025-12-18	EQ.SPY	674.4769287109375	5.05499267578125	0.7551280296730185	yfinance
2845	2025-12-19	EQ.SPY	680.5900268554688	6.11309814453125	0.906346515990491	yfinance
2846	2025-12-22	EQ.SPY	684.8300170898438	4.239990234375	0.6229874178387588	yfinance
2847	2025-12-23	EQ.SPY	687.9600219726562	3.1300048828125	0.45704843606495577	yfinance
2848	2025-12-24	EQ.SPY	690.3800048828125	2.41998291015625	0.35176214211069884	yfinance
2849	2025-12-26	EQ.SPY	690.3099975585938	-0.07000732421875	-0.010140404374925848	yfinance
2850	2025-12-29	EQ.SPY	687.8499755859375	-2.46002197265625	-0.35636481890115496	yfinance
2851	2025-12-30	EQ.SPY	687.010009765625	-0.8399658203125	-0.12211468345215601	yfinance
2852	2025-12-31	EQ.SPY	681.9199829101562	-5.09002685546875	-0.7408955885817768	yfinance
2853	2026-01-02	EQ.SPY	683.1699829101562	1.25	0.18330596423725698	yfinance
2854	2026-01-05	EQ.SPY	687.719970703125	4.54998779296875	0.6660110816910876	yfinance
2855	2026-01-06	EQ.SPY	691.8099975585938	4.09002685546875	0.5947227112347931	yfinance
2856	2026-01-07	EQ.SPY	689.5800170898438	-2.22998046875	-0.32234001772446613	yfinance
2857	2026-01-08	EQ.SPY	689.510009765625	-0.07000732421875	-0.010152168346495011	yfinance
2858	2026-01-09	EQ.SPY	694.0700073242188	4.55999755859375	0.6613388484590329	yfinance
2859	2026-01-12	EQ.SPY	695.1599731445312	1.0899658203125	0.15703975230316322	yfinance
2860	2026-01-13	EQ.SPY	693.77001953125	-1.38995361328125	-0.1999473023445013	yfinance
2861	2026-01-14	EQ.SPY	690.3599853515625	-3.4100341796875	-0.49152227448391483	yfinance
2862	2026-01-15	EQ.SPY	692.239990234375	1.8800048828125	0.27232240029889865	yfinance
2863	2026-01-16	EQ.SPY	691.6599731445312	-0.58001708984375	-0.08378844014015585	yfinance
2864	2026-01-20	EQ.SPY	677.5800170898438	-14.0799560546875	-2.0356759970762845	yfinance
2865	2026-01-21	EQ.SPY	685.4000244140625	7.82000732421875	1.154108315915972	yfinance
2866	2026-01-22	EQ.SPY	688.97998046875	3.5799560546875	0.5223163010167599	yfinance
2867	2026-01-23	EQ.SPY	689.22998046875	0.25	0.036285524556157876	yfinance
2868	2026-01-26	EQ.SPY	692.72998046875	3.5	0.5078130811459516	yfinance
2869	2026-01-27	EQ.SPY	695.489990234375	2.760009765625	0.39842504921721195	yfinance
2870	2026-01-28	EQ.SPY	695.4199829101562	-0.07000732421875	-0.010065899610597997	yfinance
2871	2026-01-29	EQ.SPY	694.0399780273438	-1.3800048828125	-0.19844193677574948	yfinance
2872	2026-01-30	EQ.SPY	691.969970703125	-2.07000732421875	-0.2982547677011764	yfinance
2873	2026-02-02	EQ.SPY	695.4099731445312	3.44000244140625	0.49713175239538104	yfinance
2874	2026-02-03	EQ.SPY	689.530029296875	-5.87994384765625	-0.8455363130712803	yfinance
2875	2026-02-04	EQ.SPY	686.1900024414062	-3.34002685546875	-0.4843917905757679	yfinance
2876	2026-02-05	EQ.SPY	677.6199951171875	-8.57000732421875	-1.2489262877231357	yfinance
2877	2026-02-06	EQ.SPY	690.6199951171875	13	1.9184793975496224	yfinance
2878	2025-12-09	EQ.LQD	109.67798614501953	\N	\N	yfinance
2879	2025-12-10	EQ.LQD	110.18424224853516	0.506256103515625	0.4615840619522663	yfinance
2880	2025-12-11	EQ.LQD	110.0254135131836	-0.1588287353515625	-0.1441483211304419	yfinance
2881	2025-12-12	EQ.LQD	109.36033630371094	-0.6650772094726562	-0.6044759917152819	yfinance
2882	2025-12-15	EQ.LQD	109.48938751220703	0.12905120849609375	0.1180054971097548	yfinance
2883	2025-12-16	EQ.LQD	109.737548828125	0.24816131591796875	0.22665330545419402	yfinance
2884	2025-12-17	EQ.LQD	109.6184310913086	-0.11911773681640625	-0.10854783808135977	yfinance
2885	2025-12-18	EQ.LQD	110.03533935546875	0.41690826416015625	0.38032679359631155	yfinance
2886	2025-12-19	EQ.LQD	109.7523193359375	-0.28302001953125	-0.25720829434346987	yfinance
2887	2025-12-22	EQ.LQD	109.73239135742188	-0.019927978515625	-0.01815722768885463	yfinance
2888	2025-12-23	EQ.LQD	109.84201049804688	0.109619140625	0.09989679370783693	yfinance
2889	2025-12-24	EQ.LQD	110.27053833007812	0.42852783203125	0.39013108926922796	yfinance
2890	2025-12-26	EQ.LQD	110.26056671142578	-0.00997161865234375	-0.009042867481516434	yfinance
2891	2025-12-29	EQ.LQD	110.4100570678711	0.1494903564453125	0.13557916570169554	yfinance
2892	2025-12-30	EQ.LQD	110.28050231933594	-0.12955474853515625	-0.11733962645768452	yfinance
2893	2025-12-31	EQ.LQD	109.81211853027344	-0.4683837890625	-0.4247203986305894	yfinance
2894	2026-01-02	EQ.LQD	109.78221893310547	-0.02989959716796875	-0.027227957686405905	yfinance
2895	2026-01-05	EQ.LQD	110.09115600585938	0.30893707275390625	0.28140902575685184	yfinance
2896	2026-01-06	EQ.LQD	110.09115600585938	0	0	yfinance
2897	2026-01-07	EQ.LQD	110.17088317871094	0.0797271728515625	0.07241923488142789	yfinance
2898	2026-01-08	EQ.LQD	109.8619384765625	-0.3089447021484375	-0.2804231873564003	yfinance
2899	2026-01-09	EQ.LQD	110.26056671142578	0.39862823486328125	0.3628447125464867	yfinance
2900	2026-01-12	EQ.LQD	110.13101959228516	-0.129547119140625	-0.11749179512171022	yfinance
2901	2026-01-13	EQ.LQD	110.37019348144531	0.23917388916015625	0.21717213737382918	yfinance
2902	2026-01-14	EQ.LQD	110.64923095703125	0.2790374755859375	0.25281959447941654	yfinance
2903	2026-01-15	EQ.LQD	110.50971221923828	-0.13951873779296875	-0.1260910144483051	yfinance
2904	2026-01-16	EQ.LQD	110.19081115722656	-0.31890106201171875	-0.2885728825164765	yfinance
2905	2026-01-20	EQ.LQD	109.52310943603516	-0.6677017211914062	-0.6059504546515146	yfinance
2906	2026-01-21	EQ.LQD	110.18083953857422	0.6577301025390625	0.6005400192944641	yfinance
2907	2026-01-22	EQ.LQD	110.39012145996094	0.20928192138671875	0.18994402498943505	yfinance
2908	2026-01-23	EQ.LQD	110.45987701416016	0.06975555419921875	0.06319003301805357	yfinance
2909	2026-01-26	EQ.LQD	110.54957580566406	0.08969879150390625	0.08120486273256262	yfinance
2910	2026-01-27	EQ.LQD	110.42998504638672	-0.11959075927734375	-0.10817839725371109	yfinance
2911	2026-01-28	EQ.LQD	110.27053833007812	-0.15944671630859375	-0.1443871573844887	yfinance
2912	2026-01-29	EQ.LQD	110.30043029785156	0.0298919677734375	0.027107846054002592	yfinance
2913	2026-01-30	EQ.LQD	110.19081115722656	-0.109619140625	-0.09938233271528331	yfinance
2914	2026-02-02	EQ.LQD	109.68255615234375	-0.5082550048828125	-0.4612498987393832	yfinance
2915	2026-02-03	EQ.LQD	109.73239135742188	0.049835205078125	0.04543585308944324	yfinance
2916	2026-02-04	EQ.LQD	109.59286499023438	-0.1395263671875	-0.127151486868661	yfinance
2917	2026-02-05	EQ.LQD	110.12104797363281	0.5281829833984375	0.48195015564699667	yfinance
2918	2026-02-06	EQ.LQD	110.18083953857422	0.05979156494140625	0.05429621860820162	yfinance
2919	2025-12-09	EQ.HYG	79.68962860107422	\N	\N	yfinance
2920	2025-12-10	EQ.HYG	79.95704650878906	0.26741790771484375	0.33557429292779883	yfinance
2921	2025-12-11	EQ.HYG	79.94713592529297	-0.00991058349609375	-0.012394884414601728	yfinance
2922	2025-12-12	EQ.HYG	79.79856872558594	-0.14856719970703125	-0.1858317974590868	yfinance
2923	2025-12-15	EQ.HYG	79.83819580078125	0.0396270751953125	0.04965887963678076	yfinance
2924	2025-12-16	EQ.HYG	79.8877182006836	0.04952239990234375	0.06202845568544167	yfinance
2925	2025-12-17	EQ.HYG	79.7886734008789	-0.0990447998046875	-0.12398000848626063	yfinance
2926	2025-12-18	EQ.HYG	80.00656127929688	0.21788787841796875	0.27308121457696605	yfinance
2927	2025-12-19	EQ.HYG	79.96775817871094	-0.0388031005859375	-0.04849989796521663	yfinance
2928	2025-12-22	EQ.HYG	80.03741455078125	0.0696563720703125	0.08710557061590413	yfinance
2929	2025-12-23	EQ.HYG	80.09712219238281	0.0597076416015625	0.07459966309091588	yfinance
2930	2025-12-24	EQ.HYG	80.24639129638672	0.14926910400390625	0.18636013369541715	yfinance
2931	2025-12-26	EQ.HYG	80.20658111572266	-0.0398101806640625	-0.049609932634883544	yfinance
2932	2025-12-29	EQ.HYG	80.23643493652344	0.02985382080078125	0.03722116113852046	yfinance
2933	2025-12-30	EQ.HYG	80.31604766845703	0.07961273193359375	0.09922266860009034	yfinance
2934	2025-12-31	EQ.HYG	80.23643493652344	-0.07961273193359375	-0.09912431480970459	yfinance
2935	2026-01-02	EQ.HYG	80.27623748779297	0.03980255126953125	0.04960657997955642	yfinance
2936	2026-01-05	EQ.HYG	80.48521423339844	0.20897674560546875	0.26032204814936216	yfinance
2937	2026-01-06	EQ.HYG	80.50511932373047	0.01990509033203125	0.024731362799518226	yfinance
2938	2026-01-07	EQ.HYG	80.48521423339844	-0.01990509033203125	-0.02472524790875483	yfinance
2939	2026-01-08	EQ.HYG	80.54492950439453	0.05971527099609375	0.07419408839855468	yfinance
2940	2026-01-09	EQ.HYG	80.60462951660156	0.05970001220703125	0.07412013713883009	yfinance
2941	2026-01-12	EQ.HYG	80.64443969726562	0.0398101806640625	0.04938944686280467	yfinance
2942	2026-01-13	EQ.HYG	80.64443969726562	0	0	yfinance
2943	2026-01-14	EQ.HYG	80.64443969726562	0	0	yfinance
2944	2026-01-15	EQ.HYG	80.64443969726562	0	0	yfinance
2945	2026-01-16	EQ.HYG	80.6941909790039	0.04975128173828125	0.0616921413615676	yfinance
2946	2026-01-20	EQ.HYG	80.48521423339844	-0.20897674560546875	-0.25897371678197145	yfinance
2947	2026-01-21	EQ.HYG	80.72405242919922	0.23883819580078125	0.2967479158447367	yfinance
2948	2026-01-22	EQ.HYG	80.78375244140625	0.05970001220703125	0.07395566799547439	yfinance
2949	2026-01-23	EQ.HYG	80.74394989013672	-0.03980255126953125	-0.04927049074428757	yfinance
2950	2026-01-26	EQ.HYG	80.78375244140625	0.03980255126953125	0.04929477852357744	yfinance
2951	2026-01-27	EQ.HYG	80.7738037109375	-0.00994873046875	-0.012315261631311289	yfinance
2952	2026-01-28	EQ.HYG	80.64443969726562	-0.129364013671875	-0.16015590170152894	yfinance
2953	2026-01-29	EQ.HYG	80.63448333740234	-0.00995635986328125	-0.012345996699408944	yfinance
2954	2026-01-30	EQ.HYG	80.72405242919922	0.089569091796875	0.11108038160558081	yfinance
2955	2026-02-02	EQ.HYG	80.3757553100586	-0.348297119140625	-0.4314663457289964	yfinance
2956	2026-02-03	EQ.HYG	80.32599639892578	-0.0497589111328125	-0.06190786132069535	yfinance
2957	2026-02-04	EQ.HYG	80.22648620605469	-0.09951019287109375	-0.123882923750977	yfinance
2958	2026-02-05	EQ.HYG	80.13692474365234	-0.08956146240234375	-0.11163577845390485	yfinance
2959	2026-02-06	EQ.HYG	80.41555786132812	0.27863311767578125	0.3476962942702038	yfinance
2960	2025-12-09	EQ.IEAC	118.72956085205078	\N	\N	yfinance
2961	2025-12-10	EQ.IEAC	118.73938751220703	0.00982666015625	0.008276506782076812	yfinance
2962	2025-12-11	EQ.IEAC	118.82787322998047	0.0884857177734375	0.07452094846315482	yfinance
2963	2025-12-12	EQ.IEAC	118.79837799072266	-0.0294952392578125	-0.02482181869966415	yfinance
2964	2025-12-15	EQ.IEAC	118.87703704833984	0.0786590576171875	0.06621223197452261	yfinance
2965	2025-12-16	EQ.IEAC	118.85736846923828	-0.0196685791015625	-0.016545314040393284	yfinance
2966	2025-12-17	EQ.IEAC	118.74922180175781	-0.10814666748046875	-0.09098861002333096	yfinance
2967	2025-12-18	EQ.IEAC	118.8475341796875	0.0983123779296875	0.08278991343102192	yfinance
2968	2025-12-19	EQ.IEAC	118.60173797607422	-0.24579620361328125	-0.2068164100415058	yfinance
2969	2025-12-22	EQ.IEAC	118.63124084472656	0.02950286865234375	0.024875578685276456	yfinance
2970	2025-12-23	EQ.IEAC	118.89669799804688	0.2654571533203125	0.22376664985554914	yfinance
2971	2025-12-24	EQ.IEAC	118.90653228759766	0.00983428955078125	0.008271289040291766	yfinance
2972	2025-12-29	EQ.IEAC	119.11299896240234	0.2064666748046875	0.1736377899788628	yfinance
2973	2025-12-30	EQ.IEAC	119.10316467285156	-0.00983428955078125	-0.008256268951708128	yfinance
2974	2025-12-31	EQ.IEAC	119.19165802001953	0.08849334716796875	0.07429974460463683	yfinance
2975	2026-01-02	EQ.IEAC	118.87703704833984	-0.3146209716796875	-0.2639622410713034	yfinance
2976	2026-01-05	EQ.IEAC	119.08350372314453	0.2064666748046875	0.17368087221145193	yfinance
2977	2026-01-06	EQ.IEAC	119.2850570678711	0.2015533447265625	0.1692537911843364	yfinance
2978	2026-01-07	EQ.IEAC	119.43745422363281	0.15239715576171875	0.12775879855178127	yfinance
2979	2026-01-08	EQ.IEAC	119.3686294555664	-0.06882476806640625	-0.05762410837854919	yfinance
2980	2026-01-09	EQ.IEAC	119.44728088378906	0.07865142822265625	0.06588952941939685	yfinance
2981	2026-01-12	EQ.IEAC	119.47677612304688	0.0294952392578125	0.024693102295487653	yfinance
2982	2026-01-13	EQ.IEAC	119.58492279052734	0.10814666748046875	0.09051689457128517	yfinance
2983	2026-01-14	EQ.IEAC	119.5750961303711	-0.00982666015625	-0.008217306937148767	yfinance
2984	2026-01-15	EQ.IEAC	119.6500015258789	0.0749053955078125	0.06264297327107658	yfinance
2985	2026-01-16	EQ.IEAC	119.56999969482422	-0.0800018310546875	-0.0668632093894157	yfinance
2986	2026-01-19	EQ.IEAC	119.5999984741211	0.029998779296875	0.02508888464785498	yfinance
2987	2026-01-20	EQ.IEAC	119.45999908447266	-0.1399993896484375	-0.1170563473533241	yfinance
2988	2026-01-21	EQ.IEAC	119.61000061035156	0.15000152587890625	0.1255663209681067	yfinance
2989	2026-01-22	EQ.IEAC	119.55000305175781	-0.05999755859375	-0.05016098845212911	yfinance
2990	2026-01-23	EQ.IEAC	119.48999786376953	-0.06000518798828125	-0.05019254408743318	yfinance
2991	2026-01-26	EQ.IEAC	119.66000366210938	0.17000579833984375	0.14227617489261926	yfinance
2992	2026-01-27	EQ.IEAC	119.75	0.089996337890625	0.07521004106330523	yfinance
2993	2026-01-28	EQ.IEAC	119.86000061035156	0.1100006103515625	0.09185854726644051	yfinance
2994	2026-01-29	EQ.IEAC	119.91000366210938	0.0500030517578125	0.0417178804465099	yfinance
2995	2026-01-30	EQ.IEAC	120.05000305175781	0.1399993896484375	0.11675371976714918	yfinance
2996	2026-02-02	EQ.IEAC	119.87000274658203	-0.18000030517578125	-0.14993777642652514	yfinance
2997	2026-02-03	EQ.IEAC	119.8499984741211	-0.0200042724609375	-0.01668830566662175	yfinance
2998	2026-02-04	EQ.IEAC	119.94000244140625	0.09000396728515625	0.07509717849899729	yfinance
2999	2026-02-05	EQ.IEAC	119.95999908447266	0.01999664306640625	0.01667220498530098	yfinance
3000	2026-02-06	EQ.IEAC	120	0.04000091552734375	0.03334521159772281	yfinance
3001	2025-12-09	EQ.IWM	250.5498046875	\N	\N	yfinance
3002	2025-12-10	EQ.IWM	253.9583740234375	3.4085693359375	1.3604358383710824	yfinance
3003	2025-12-11	EQ.IWM	256.9383544921875	2.97998046875	1.1734129580129464	yfinance
3004	2025-12-12	EQ.IWM	253.0015869140625	-3.936767578125	-1.5321836967102946	yfinance
3005	2025-12-15	EQ.IWM	251.08798217773438	-1.913604736328125	-0.7563607642422111	yfinance
3006	2025-12-16	EQ.IWM	249.89999389648438	-1.18798828125	-0.47313625723794067	yfinance
3007	2025-12-17	EQ.IWM	247.24000549316406	-2.6599884033203125	-1.0644211557772805	yfinance
3008	2025-12-18	EQ.IWM	248.7100067138672	1.470001220703125	0.5945644669320188	yfinance
3009	2025-12-19	EQ.IWM	250.7899932861328	2.079986572265625	0.8363099658706464	yfinance
3010	2025-12-22	EQ.IWM	253.5800018310547	2.790008544921875	1.1124879858099768	yfinance
3011	2025-12-23	EQ.IWM	252.0800018310547	-1.5	-0.5915292961466895	yfinance
3012	2025-12-24	EQ.IWM	252.7100067138672	0.6300048828125	0.2499225953016029	yfinance
3013	2025-12-26	EQ.IWM	251.4199981689453	-1.290008544921875	-0.5104699104307717	yfinance
3014	2025-12-29	EQ.IWM	249.8800048828125	-1.5399932861328125	-0.6125182154754419	yfinance
3015	2025-12-30	EQ.IWM	248.02999877929688	-1.850006103515625	-0.7403577986895077	yfinance
3016	2025-12-31	EQ.IWM	246.16000366210938	-1.8699951171875	-0.7539390905901939	yfinance
3017	2026-01-02	EQ.IWM	248.77999877929688	2.6199951171875	1.064346391863004	yfinance
3018	2026-01-05	EQ.IWM	252.72999572753906	3.9499969482421875	1.5877469923723229	yfinance
3019	2026-01-06	EQ.IWM	256.0799865722656	3.3499908447265625	1.325521663972998	yfinance
3020	2026-01-07	EQ.IWM	255.47999572753906	-0.5999908447265625	-0.23429821781767604	yfinance
3021	2026-01-08	EQ.IWM	258.2699890136719	2.7899932861328125	1.0920593912598338	yfinance
3022	2026-01-09	EQ.IWM	260.2300109863281	1.96002197265625	0.7589042691880448	yfinance
3023	2026-01-12	EQ.IWM	261.5	1.269989013671875	0.4880255773952979	yfinance
3024	2026-01-13	EQ.IWM	261.3500061035156	-0.149993896484375	-0.05735904263264818	yfinance
3025	2026-01-14	EQ.IWM	263.19000244140625	1.839996337890625	0.7040353146813544	yfinance
3026	2026-01-15	EQ.IWM	265.510009765625	2.32000732421875	0.8814952326068127	yfinance
3027	2026-01-16	EQ.IWM	265.760009765625	0.25	0.09415840864933257	yfinance
3028	2026-01-20	EQ.IWM	262.5799865722656	-3.180023193359375	-1.1965770155426516	yfinance
3029	2026-01-21	EQ.IWM	267.7900085449219	5.21002197265625	1.9841656786825907	yfinance
3030	2026-01-22	EQ.IWM	269.7900085449219	2	0.746853854207372	yfinance
3031	2026-01-23	EQ.IWM	264.80999755859375	-4.980010986328125	-1.8458841427031274	yfinance
3032	2026-01-26	EQ.IWM	263.9800109863281	-0.829986572265625	-0.3134272043796142	yfinance
3033	2026-01-27	EQ.IWM	264.7300109863281	0.75	0.2841124209358577	yfinance
3034	2026-01-28	EQ.IWM	263.29998779296875	-1.430023193359375	-0.5401817451793284	yfinance
3035	2026-01-29	EQ.IWM	263.3699951171875	0.07000732421875	0.026588426686064395	yfinance
3036	2026-01-30	EQ.IWM	259.6499938964844	-3.720001220703125	-1.4124620456661725	yfinance
3037	2026-02-02	EQ.IWM	262.17999267578125	2.529998779296875	0.9743881528090923	yfinance
3038	2026-02-03	EQ.IWM	262.7799987792969	0.600006103515625	0.22885274249649115	yfinance
3039	2026-02-04	EQ.IWM	260.5199890136719	-2.260009765625	-0.8600387305439986	yfinance
3040	2026-02-05	EQ.IWM	255.8300018310547	-4.6899871826171875	-1.8002408185158725	yfinance
3041	2026-02-06	EQ.IWM	265.0199890136719	9.189987182617188	3.59222417888504	yfinance
3042	2025-12-09	EQ.IHYG	92.79000091552734	\N	\N	yfinance
3043	2025-12-10	EQ.IHYG	92.66000366210938	-0.12999725341796875	-0.1400983426396488	yfinance
3044	2025-12-11	EQ.IHYG	92.77999877929688	0.1199951171875	0.12950044511661132	yfinance
3045	2025-12-12	EQ.IHYG	92.68000030517578	-0.09999847412109375	-0.10778020633409151	yfinance
3046	2025-12-15	EQ.IHYG	92.7699966430664	0.089996337890625	0.09710437806893175	yfinance
3047	2025-12-16	EQ.IHYG	92.81999969482422	0.0500030517578125	0.05390002540390273	yfinance
3048	2025-12-17	EQ.IHYG	92.9000015258789	0.0800018310546875	0.08619029445994333	yfinance
3049	2025-12-18	EQ.IHYG	93.12000274658203	0.220001220703125	0.23681508836341605	yfinance
3050	2025-12-19	EQ.IHYG	93.02999877929688	-0.09000396728515625	-0.09665374208599864	yfinance
3051	2025-12-22	EQ.IHYG	92.98999786376953	-0.04000091552734375	-0.042997867410749284	yfinance
3052	2025-12-23	EQ.IHYG	93.05999755859375	0.06999969482421875	0.07527658504387578	yfinance
3053	2025-12-24	EQ.IHYG	93.33000183105469	0.2700042724609375	0.29013999521215716	yfinance
3054	2025-12-29	EQ.IHYG	93.0199966430664	-0.31000518798828125	-0.3321602720521215	yfinance
3055	2025-12-30	EQ.IHYG	93.27999877929688	0.26000213623046875	0.27951208945764777	yfinance
3056	2025-12-31	EQ.IHYG	93.48999786376953	0.20999908447265625	0.22512766640308396	yfinance
3057	2026-01-02	EQ.IHYG	93.13999938964844	-0.34999847412109375	-0.3743699669681239	yfinance
3058	2026-01-05	EQ.IHYG	93.4000015258789	0.26000213623046875	0.2791519625663272	yfinance
3059	2026-01-06	EQ.IHYG	93.44000244140625	0.04000091552734375	0.0428275319848474	yfinance
3060	2026-01-07	EQ.IHYG	93.56999969482422	0.12999725341796875	0.13912376928659284	yfinance
3061	2026-01-08	EQ.IHYG	93.56999969482422	0	0	yfinance
3062	2026-01-09	EQ.IHYG	93.61000061035156	0.04000091552734375	0.04274972283617137	yfinance
3063	2026-01-12	EQ.IHYG	93.58000183105469	-0.029998779296875	-0.03204655389518039	yfinance
3064	2026-01-13	EQ.IHYG	93.55000305175781	-0.029998779296875	-0.03205682700352315	yfinance
3065	2026-01-14	EQ.IHYG	93.45999908447266	-0.09000396728515625	-0.09620947552012407	yfinance
3066	2026-01-15	EQ.IHYG	93.45999908447266	0	0	yfinance
3067	2026-01-16	EQ.IHYG	93.33999633789062	-0.12000274658203125	-0.12840011529806272	yfinance
3068	2026-01-19	EQ.IHYG	93.22000122070312	-0.1199951171875	-0.12855701938654238	yfinance
3069	2026-01-20	EQ.IHYG	93.2300033569336	0.01000213623046875	0.010729603196194109	yfinance
3070	2026-01-21	EQ.IHYG	93.41999816894531	0.18999481201171875	0.20379148897412183	yfinance
3071	2026-01-22	EQ.IHYG	93.4800033569336	0.06000518798828125	0.06423163044786719	yfinance
3072	2026-01-23	EQ.IHYG	93.58999633789062	0.10999298095703125	0.11766471652450242	yfinance
3073	2026-01-26	EQ.IHYG	93.62999725341797	0.04000091552734375	0.042740588837002734	yfinance
3074	2026-01-27	EQ.IHYG	93.73999786376953	0.1100006103515625	0.11748436780771872	yfinance
3075	2026-01-28	EQ.IHYG	93.69000244140625	-0.04999542236328125	-0.0533341407111387	yfinance
3076	2026-01-29	EQ.IHYG	93.4000015258789	-0.29000091552734375	-0.30953240257274023	yfinance
3077	2026-01-30	EQ.IHYG	93.62999725341797	0.2299957275390625	0.24624809826725344	yfinance
3078	2026-02-02	EQ.IHYG	93.5999984741211	-0.029998779296875	-0.03203970968372521	yfinance
3079	2026-02-03	EQ.IHYG	93.6500015258789	0.0500030517578125	0.053422064714709956	yfinance
3080	2026-02-04	EQ.IHYG	93.58000183105469	-0.06999969482421875	-0.07474606906960411	yfinance
3081	2026-02-05	EQ.IHYG	93.55000305175781	-0.029998779296875	-0.03205682700352315	yfinance
3082	2026-02-06	EQ.IHYG	93.69999694824219	0.149993896484375	0.16033553350221574	yfinance
3083	2025-12-09	CM.SILVER	60.16899871826172	\N	\N	yfinance
3084	2025-12-10	CM.SILVER	60.37900161743164	0.21000289916992188	0.34902176144437735	yfinance
3085	2025-12-11	CM.SILVER	63.92900085449219	3.549999237060547	5.879526229257241	yfinance
3086	2025-12-12	CM.SILVER	61.36199951171875	-2.5670013427734375	-4.015394122326657	yfinance
3087	2025-12-15	CM.SILVER	62.939998626708984	1.5779991149902344	2.5716227103858835	yfinance
3088	2025-12-16	CM.SILVER	62.70000076293945	-0.23999786376953125	-0.3813121528536015	yfinance
3089	2025-12-17	CM.SILVER	66.23699951171875	3.536998748779297	5.641146261149547	yfinance
3090	2025-12-18	CM.SILVER	64.59200286865234	-1.6449966430664062	-2.483501147686152	yfinance
3091	2025-12-19	CM.SILVER	66.84500122070312	2.2529983520507812	3.48804534925515	yfinance
3092	2025-12-22	CM.SILVER	67.90599822998047	1.0609970092773438	1.58724959219349	yfinance
3093	2025-12-23	CM.SILVER	70.48500061035156	2.5790023803710938	3.7979006974268517	yfinance
3094	2025-12-24	CM.SILVER	71.03099822998047	0.5459976196289062	0.7746295167779569	yfinance
3095	2025-12-26	CM.SILVER	76.48600006103516	5.4550018310546875	7.67974823244461	yfinance
3096	2025-12-29	CM.SILVER	69.85600280761719	-6.629997253417969	-8.668249415745743	yfinance
3097	2025-12-30	CM.SILVER	77.3740005493164	7.517997741699219	10.762135592561341	yfinance
3098	2025-12-31	CM.SILVER	70.13400268554688	-7.239997863769531	-9.357145568755907	yfinance
3099	2026-01-02	CM.SILVER	70.55599975585938	0.4219970703125	0.6017011066722769	yfinance
3100	2026-01-05	CM.SILVER	76.16400146484375	5.608001708984375	7.948298838354501	yfinance
3101	2026-01-06	CM.SILVER	80.52999877929688	4.365997314453125	5.732363361276927	yfinance
3102	2026-01-07	CM.SILVER	77.13500213623047	-3.3949966430664062	-4.215816086587613	yfinance
3103	2026-01-08	CM.SILVER	74.71600341796875	-2.4189987182617188	-3.136058405740952	yfinance
3104	2026-01-09	CM.SILVER	78.88400268554688	4.167999267578125	5.578455855383381	yfinance
3105	2026-01-12	CM.SILVER	84.61000061035156	5.7259979248046875	7.2587568199728345	yfinance
3106	2026-01-13	CM.SILVER	85.87699890136719	1.266998291015625	1.4974568985650318	yfinance
3107	2026-01-14	CM.SILVER	90.86900329589844	4.99200439453125	5.812970246276009	yfinance
3108	2026-01-15	CM.SILVER	91.8759994506836	1.0069961547851562	1.108184439424361	yfinance
3109	2026-01-16	CM.SILVER	88.09100341796875	-3.7849960327148438	-4.11967875761343	yfinance
3110	2026-01-20	CM.SILVER	94.20600128173828	6.114997863769531	6.941682608331145	yfinance
3111	2026-01-21	CM.SILVER	92.20999908447266	-1.996002197265625	-2.118763316676883	yfinance
3112	2026-01-22	CM.SILVER	95.97599792480469	3.7659988403320312	4.084154514394949	yfinance
3113	2026-01-23	CM.SILVER	100.92500305175781	4.949005126953125	5.156502911103434	yfinance
3114	2026-01-26	CM.SILVER	115.08000183105469	14.154998779296875	14.02526465323732	yfinance
3115	2026-01-27	CM.SILVER	105.52300262451172	-9.556999206542969	-8.304656807855546	yfinance
3116	2026-01-28	CM.SILVER	113.11100006103516	7.5879974365234375	7.190846780132124	yfinance
3117	2026-01-29	CM.SILVER	114.03700256347656	0.9260025024414062	0.8186670632756597	yfinance
3118	2026-01-30	CM.SILVER	78.29000091552734	-35.74700164794922	-31.346844308759625	yfinance
3119	2026-02-02	CM.SILVER	76.77799987792969	-1.5120010375976562	-1.9312824369858699	yfinance
3120	2026-02-03	CM.SILVER	83.04199981689453	6.263999938964844	8.158587028737472	yfinance
3121	2026-02-04	CM.SILVER	84.16500091552734	1.1230010986328125	1.352329063737628	yfinance
3122	2026-02-05	CM.SILVER	76.52899932861328	-7.6360015869140625	-9.072656690847039	yfinance
3123	2026-02-06	CM.SILVER	76.73500061035156	0.20600128173828125	0.2691806812391702	yfinance
3124	2025-12-09	EQ.MOVE	75.37999725341797	\N	\N	yfinance
3125	2025-12-10	EQ.MOVE	68.62000274658203	-6.7599945068359375	-8.967889033094144	yfinance
3126	2025-12-11	EQ.MOVE	69.23999786376953	0.6199951171875	0.9035195167175682	yfinance
3127	2025-12-12	EQ.MOVE	69.25	0.01000213623046875	0.014445604475823446	yfinance
3128	2025-12-15	EQ.MOVE	73.30999755859375	4.05999755859375	5.862812358980144	yfinance
3129	2025-12-16	EQ.MOVE	67.13999938964844	-6.1699981689453125	-8.416312064413697	yfinance
3130	2025-12-17	EQ.MOVE	62.7400016784668	-4.399997711181641	-6.553467010993192	yfinance
3131	2025-12-18	EQ.MOVE	60.0099983215332	-2.7300033569335938	-4.351296276535751	yfinance
3132	2025-12-19	EQ.MOVE	59.40999984741211	-0.5999984741210938	-0.9998308463638103	yfinance
3133	2025-12-22	EQ.MOVE	61.70000076293945	2.2900009155273438	3.854571488653346	yfinance
3134	2025-12-23	EQ.MOVE	61.16999816894531	-0.5300025939941406	-0.8589993313460224	yfinance
3135	2025-12-24	EQ.MOVE	59.47999954223633	-1.6899986267089844	-2.7627900560686305	yfinance
3136	2025-12-26	EQ.MOVE	58.5	-0.9799995422363281	-1.647611885975953	yfinance
3137	2025-12-29	EQ.MOVE	59.209999084472656	0.7099990844726562	1.2136736486712072	yfinance
3138	2025-12-30	EQ.MOVE	63.97999954223633	4.770000457763672	8.056072507210299	yfinance
3139	2025-12-31	EQ.MOVE	63.959999084472656	-0.020000457763671875	-0.03126048438069868	yfinance
3140	2026-01-02	EQ.MOVE	62.36000061035156	-1.5999984741210938	-2.501561127303893	yfinance
3141	2026-01-05	EQ.MOVE	64.70999908447266	2.3499984741210938	3.768438824760052	yfinance
3142	2026-01-06	EQ.MOVE	65.81999969482422	1.1100006103515625	1.7153463545912957	yfinance
3143	2026-01-07	EQ.MOVE	66.1500015258789	0.3300018310546875	0.501370149779319	yfinance
3144	2026-01-08	EQ.MOVE	66.94000244140625	0.7900009155273438	1.1942568364390485	yfinance
3145	2026-01-09	EQ.MOVE	61.54999923706055	-5.390003204345703	-8.051991347122621	yfinance
3146	2026-01-12	EQ.MOVE	62.900001525878906	1.3500022888183594	2.193342494804605	yfinance
3147	2026-01-13	EQ.MOVE	60.790000915527344	-2.1100006103515625	-3.354531890565132	yfinance
3148	2026-01-14	EQ.MOVE	58.11000061035156	-2.6800003051757812	-4.408620274409701	yfinance
3149	2026-01-15	EQ.MOVE	56.13999938964844	-1.970001220703125	-3.3901242471372375	yfinance
3150	2026-01-16	EQ.MOVE	58.04999923706055	1.9099998474121094	3.4022085289945534	yfinance
3151	2026-01-20	EQ.MOVE	66.66999816894531	8.619998931884766	14.84926622769281	yfinance
3152	2026-01-21	EQ.MOVE	59.560001373291016	-7.109996795654297	-10.664462263276485	yfinance
3153	2026-01-22	EQ.MOVE	56.5	-3.0600013732910156	-5.137678480080152	yfinance
3154	2026-01-23	EQ.MOVE	56.25	-0.25	-0.4424778761061947	yfinance
3155	2026-01-26	EQ.MOVE	55.77000045776367	-0.4799995422363281	-0.85333251953125	yfinance
3156	2026-01-27	EQ.MOVE	56.119998931884766	0.34999847412109375	0.6275748094823099	yfinance
3157	2026-01-28	EQ.MOVE	57.43000030517578	1.3100013732910156	2.334286169322669	yfinance
3158	2026-01-29	EQ.MOVE	60.72999954223633	3.299999237060547	5.746124359263045	yfinance
3159	2026-01-30	EQ.MOVE	59.20000076293945	-1.529998779296875	-2.5193459424164755	yfinance
3160	2026-02-02	EQ.MOVE	59.29999923706055	0.09999847412109375	0.1689163392438587	yfinance
3161	2026-02-03	EQ.MOVE	57.540000915527344	-1.7599983215332031	-2.96795673554286	yfinance
3162	2026-02-04	EQ.MOVE	57.5099983215332	-0.030002593994140625	-0.05214215070692558	yfinance
3163	2026-02-05	EQ.MOVE	62.15999984741211	4.650001525878906	8.085553228294614	yfinance
3164	2026-02-06	EQ.MOVE	63.619998931884766	1.4599990844726562	2.3487758816869433	yfinance
1559	2025-12-10	RATES.US2Y	3.54	-0.06999999999999984	-1.939058171745148	fred
1560	2025-12-11	RATES.US2Y	3.52	-0.020000000000000018	-0.5649717514124298	fred
1561	2025-12-12	RATES.US2Y	3.52	0	0	fred
1562	2025-12-15	RATES.US2Y	3.51	-0.010000000000000231	-0.28409090909091567	fred
1563	2025-12-16	RATES.US2Y	3.48	-0.029999999999999805	-0.8547008547008492	fred
1564	2025-12-17	RATES.US2Y	3.49	0.010000000000000231	0.2873563218390871	fred
1565	2025-12-18	RATES.US2Y	3.46	-0.03000000000000025	-0.8595988538682019	fred
1566	2025-12-19	RATES.US2Y	3.48	0.020000000000000018	0.5780346820809253	fred
1567	2025-12-22	RATES.US2Y	3.44	-0.040000000000000036	-1.1494252873563229	fred
1568	2025-12-23	RATES.US2Y	3.48	0.040000000000000036	1.1627906976744196	fred
1569	2025-12-24	RATES.US2Y	3.47	-0.009999999999999787	-0.28735632183907434	fred
1570	2025-12-26	RATES.US2Y	3.46	-0.010000000000000231	-0.2881844380403525	fred
1571	2025-12-29	RATES.US2Y	3.45	-0.009999999999999787	-0.2890173410404563	fred
1572	2025-12-30	RATES.US2Y	3.45	0	0	fred
1573	2025-12-31	RATES.US2Y	3.47	0.020000000000000018	0.5797101449275367	fred
1574	2026-01-02	RATES.US2Y	3.47	0	0	fred
1575	2026-01-05	RATES.US2Y	3.46	-0.010000000000000231	-0.2881844380403525	fred
1576	2026-01-06	RATES.US2Y	3.47	0.010000000000000231	0.2890173410404691	fred
1577	2026-01-07	RATES.US2Y	3.47	0	0	fred
1578	2026-01-08	RATES.US2Y	3.49	0.020000000000000018	0.5763688760806921	fred
1579	2026-01-09	RATES.US2Y	3.54	0.04999999999999982	1.4326647564469863	fred
1580	2026-01-12	RATES.US2Y	3.54	0	0	fred
1581	2026-01-13	RATES.US2Y	3.53	-0.010000000000000231	-0.2824858757062212	fred
1582	2026-01-14	RATES.US2Y	3.51	-0.020000000000000018	-0.5665722379603405	fred
1583	2026-01-15	RATES.US2Y	3.56	0.050000000000000266	1.4245014245014322	fred
1584	2026-01-16	RATES.US2Y	3.59	0.029999999999999805	0.8426966292134777	fred
1585	2026-01-20	RATES.US2Y	3.6	0.010000000000000231	0.27855153203343264	fred
1586	2026-01-21	RATES.US2Y	3.6	0	0	fred
1587	2026-01-22	RATES.US2Y	3.61	0.009999999999999787	0.27777777777777185	fred
1588	2026-01-23	RATES.US2Y	3.6	-0.009999999999999787	-0.27700831024930156	fred
1589	2026-01-26	RATES.US2Y	3.56	-0.040000000000000036	-1.111111111111112	fred
1590	2026-01-27	RATES.US2Y	3.53	-0.03000000000000025	-0.8426966292134901	fred
1591	2026-01-28	RATES.US2Y	3.56	0.03000000000000025	0.849858356940517	fred
1592	2026-01-29	RATES.US2Y	3.53	-0.03000000000000025	-0.8426966292134901	fred
1593	2026-01-30	RATES.US2Y	3.52	-0.009999999999999787	-0.2832861189801639	fred
1594	2026-02-02	RATES.US2Y	3.57	0.04999999999999982	1.4204545454545403	fred
1595	2026-02-03	RATES.US2Y	3.57	0	0	fred
1596	2026-02-04	RATES.US2Y	3.57	0	0	fred
1597	2026-02-05	RATES.US2Y	3.47	-0.09999999999999964	-2.8011204481792618	fred
1598	2026-02-06	RATES.US2Y	3.5	0.029999999999999805	0.8645533141210318	fred
767	2026-02-09	RATES.US2Y	3.48	\N	\N	fred
768	2026-02-10	RATES.US2Y	3.45	-0.029999999999999805	-0.8620689655172358	fred
769	2026-02-11	RATES.US2Y	3.52	0.06999999999999984	2.028985507246372	fred
770	2026-02-12	RATES.US2Y	3.47	-0.04999999999999982	-1.4204545454545403	fred
771	2026-02-13	RATES.US2Y	3.4	-0.07000000000000028	-2.017291066282429	fred
772	2026-02-17	RATES.US2Y	3.43	0.03000000000000025	0.8823529411764779	fred
773	2026-02-18	RATES.US2Y	3.47	0.040000000000000036	1.1661807580174937	fred
774	2026-02-19	RATES.US2Y	3.47	0	0	fred
775	2026-02-20	RATES.US2Y	3.48	0.009999999999999787	0.28818443804033966	fred
776	2026-02-23	RATES.US2Y	3.43	-0.04999999999999982	-1.436781609195397	fred
777	2026-02-24	RATES.US2Y	3.43	0	0	fred
778	2026-02-25	RATES.US2Y	3.45	0.020000000000000018	0.5830903790087468	fred
779	2026-02-26	RATES.US2Y	3.42	-0.03000000000000025	-0.8695652173913115	fred
780	2026-02-27	RATES.US2Y	3.38	-0.040000000000000036	-1.1695906432748548	fred
781	2026-03-02	RATES.US2Y	3.47	0.0900000000000003	2.6627218934911334	fred
782	2026-03-03	RATES.US2Y	3.51	0.03999999999999959	1.1527377521613715	fred
783	2026-03-04	RATES.US2Y	3.54	0.03000000000000025	0.8547008547008619	fred
784	2026-03-05	RATES.US2Y	3.57	0.029999999999999805	0.8474576271186386	fred
1517	2025-12-09	RATES.US10Y	4.18	\N	\N	fred
1518	2025-12-10	RATES.US10Y	4.13	-0.04999999999999982	-1.1961722488038236	fred
1519	2025-12-11	RATES.US10Y	4.14	0.009999999999999787	0.24213075060532172	fred
1520	2025-12-12	RATES.US10Y	4.19	0.05000000000000071	1.2077294685990512	fred
1521	2025-12-15	RATES.US10Y	4.18	-0.010000000000000675	-0.2386634844868896	fred
1522	2025-12-16	RATES.US10Y	4.15	-0.02999999999999936	-0.7177033492822814	fred
1523	2025-12-17	RATES.US10Y	4.16	0.009999999999999787	0.24096385542168158	fred
1524	2025-12-18	RATES.US10Y	4.12	-0.040000000000000036	-0.9615384615384623	fred
1525	2025-12-19	RATES.US10Y	4.16	0.040000000000000036	0.9708737864077678	fred
1526	2025-12-22	RATES.US10Y	4.17	0.009999999999999787	0.24038461538461026	fred
1527	2025-12-23	RATES.US10Y	4.18	0.009999999999999787	0.23980815347721313	fred
1528	2025-12-24	RATES.US10Y	4.15	-0.02999999999999936	-0.7177033492822814	fred
1529	2025-12-26	RATES.US10Y	4.14	-0.010000000000000675	-0.24096385542170298	fred
1530	2025-12-29	RATES.US10Y	4.12	-0.019999999999999574	-0.4830917874396033	fred
1531	2025-12-30	RATES.US10Y	4.14	0.019999999999999574	0.4854368932038731	fred
1532	2025-12-31	RATES.US10Y	4.18	0.040000000000000036	0.966183574879228	fred
1533	2026-01-02	RATES.US10Y	4.19	0.010000000000000675	0.2392344497607817	fred
1534	2026-01-05	RATES.US10Y	4.17	-0.020000000000000462	-0.477326968973758	fred
1535	2026-01-06	RATES.US10Y	4.18	0.009999999999999787	0.23980815347721313	fred
1536	2026-01-07	RATES.US10Y	4.15	-0.02999999999999936	-0.7177033492822814	fred
1537	2026-01-08	RATES.US10Y	4.19	0.040000000000000036	0.9638554216867478	fred
1538	2026-01-09	RATES.US10Y	4.18	-0.010000000000000675	-0.2386634844868896	fred
1539	2026-01-12	RATES.US10Y	4.19	0.010000000000000675	0.2392344497607817	fred
1540	2026-01-13	RATES.US10Y	4.18	-0.010000000000000675	-0.2386634844868896	fred
1541	2026-01-14	RATES.US10Y	4.15	-0.02999999999999936	-0.7177033492822814	fred
1542	2026-01-15	RATES.US10Y	4.17	0.019999999999999574	0.48192771084336317	fred
1543	2026-01-16	RATES.US10Y	4.24	0.07000000000000028	1.6786570743405345	fred
1544	2026-01-20	RATES.US10Y	4.3	0.05999999999999961	1.4150943396226323	fred
1545	2026-01-21	RATES.US10Y	4.26	-0.040000000000000036	-0.9302325581395358	fred
1546	2026-01-22	RATES.US10Y	4.26	0	0	fred
1547	2026-01-23	RATES.US10Y	4.24	-0.019999999999999574	-0.4694835680751074	fred
1548	2026-01-26	RATES.US10Y	4.22	-0.020000000000000462	-0.47169811320755806	fred
1549	2026-01-27	RATES.US10Y	4.24	0.020000000000000462	0.4739336492891105	fred
1550	2026-01-28	RATES.US10Y	4.26	0.019999999999999574	0.4716981132075371	fred
1551	2026-01-29	RATES.US10Y	4.24	-0.019999999999999574	-0.4694835680751074	fred
1552	2026-01-30	RATES.US10Y	4.26	0.019999999999999574	0.4716981132075371	fred
1553	2026-02-02	RATES.US10Y	4.29	0.03000000000000025	0.7042253521126819	fred
1554	2026-02-03	RATES.US10Y	4.28	-0.009999999999999787	-0.23310023310022812	fred
1555	2026-02-04	RATES.US10Y	4.29	0.009999999999999787	0.23364485981307911	fred
1556	2026-02-05	RATES.US10Y	4.21	-0.08000000000000007	-1.8648018648018665	fred
1557	2026-02-06	RATES.US10Y	4.22	0.009999999999999787	0.23752969121139636	fred
749	2026-02-09	RATES.US10Y	4.22	\N	\N	fred
750	2026-02-10	RATES.US10Y	4.16	-0.05999999999999961	-1.4218009478672895	fred
751	2026-02-11	RATES.US10Y	4.18	0.019999999999999574	0.4807692307692205	fred
752	2026-02-12	RATES.US10Y	4.09	-0.08999999999999986	-2.1531100478468868	fred
753	2026-02-13	RATES.US10Y	4.04	-0.04999999999999982	-1.222493887530558	fred
754	2026-02-17	RATES.US10Y	4.05	0.009999999999999787	0.24752475247524225	fred
755	2026-02-18	RATES.US10Y	4.09	0.040000000000000036	0.9876543209876553	fred
756	2026-02-19	RATES.US10Y	4.08	-0.009999999999999787	-0.24449877750610727	fred
757	2026-02-20	RATES.US10Y	4.08	0	0	fred
758	2026-02-23	RATES.US10Y	4.03	-0.04999999999999982	-1.225490196078427	fred
759	2026-02-24	RATES.US10Y	4.04	0.009999999999999787	0.24813895781637188	fred
760	2026-02-25	RATES.US10Y	4.05	0.009999999999999787	0.24752475247524225	fred
761	2026-02-26	RATES.US10Y	4.02	-0.03000000000000025	-0.7407407407407469	fred
762	2026-02-27	RATES.US10Y	3.97	-0.04999999999999938	-1.2437810945273478	fred
763	2026-03-02	RATES.US10Y	4.05	0.07999999999999963	2.0151133501259353	fred
764	2026-03-03	RATES.US10Y	4.06	0.009999999999999787	0.24691358024690832	fred
765	2026-03-04	RATES.US10Y	4.09	0.03000000000000025	0.7389162561576417	fred
766	2026-03-05	RATES.US10Y	4.13	0.040000000000000036	0.9779951100244508	fred
1640	2025-12-09	RATES.2S10S	0.57	\N	\N	fred
1641	2025-12-10	RATES.2S10S	0.59	0.020000000000000018	3.5087719298245648	fred
1642	2025-12-11	RATES.2S10S	0.62	0.030000000000000027	5.0847457627118695	fred
1643	2025-12-12	RATES.2S10S	0.67	0.050000000000000044	8.064516129032265	fred
1644	2025-12-15	RATES.2S10S	0.67	0	0	fred
1645	2025-12-16	RATES.2S10S	0.67	0	0	fred
1646	2025-12-17	RATES.2S10S	0.67	0	0	fred
1647	2025-12-18	RATES.2S10S	0.66	-0.010000000000000009	-1.492537313432837	fred
1648	2025-12-19	RATES.2S10S	0.68	0.020000000000000018	3.030303030303033	fred
1649	2025-12-22	RATES.2S10S	0.73	0.04999999999999993	7.352941176470577	fred
1650	2025-12-23	RATES.2S10S	0.7	-0.030000000000000027	-4.109589041095894	fred
1651	2025-12-24	RATES.2S10S	0.68	-0.019999999999999907	-2.857142857142844	fred
1652	2025-12-26	RATES.2S10S	0.68	0	0	fred
1653	2025-12-29	RATES.2S10S	0.67	-0.010000000000000009	-1.4705882352941189	fred
1654	2025-12-30	RATES.2S10S	0.69	0.019999999999999907	2.9850746268656576	fred
1655	2025-12-31	RATES.2S10S	0.71	0.020000000000000018	2.898550724637684	fred
1656	2026-01-02	RATES.2S10S	0.72	0.010000000000000009	1.4084507042253533	fred
1657	2026-01-05	RATES.2S10S	0.71	-0.010000000000000009	-1.3888888888888902	fred
1658	2026-01-06	RATES.2S10S	0.71	0	0	fred
1659	2026-01-07	RATES.2S10S	0.68	-0.029999999999999916	-4.2253521126760445	fred
1660	2026-01-08	RATES.2S10S	0.7	0.019999999999999907	2.9411764705882213	fred
1661	2026-01-09	RATES.2S10S	0.64	-0.05999999999999994	-8.571428571428564	fred
1662	2026-01-12	RATES.2S10S	0.65	0.010000000000000009	1.5625000000000013	fred
1663	2026-01-13	RATES.2S10S	0.65	0	0	fred
1664	2026-01-14	RATES.2S10S	0.64	-0.010000000000000009	-1.5384615384615399	fred
1665	2026-01-15	RATES.2S10S	0.61	-0.030000000000000027	-4.687500000000004	fred
1666	2026-01-16	RATES.2S10S	0.65	0.040000000000000036	6.557377049180334	fred
1667	2026-01-20	RATES.2S10S	0.7	0.04999999999999993	7.692307692307681	fred
1668	2026-01-21	RATES.2S10S	0.66	-0.039999999999999925	-5.714285714285704	fred
1669	2026-01-22	RATES.2S10S	0.65	-0.010000000000000009	-1.5151515151515165	fred
1670	2026-01-23	RATES.2S10S	0.64	-0.010000000000000009	-1.5384615384615399	fred
1671	2026-01-26	RATES.2S10S	0.66	0.020000000000000018	3.1250000000000027	fred
1672	2026-01-27	RATES.2S10S	0.71	0.04999999999999993	7.575757575757565	fred
1673	2026-01-28	RATES.2S10S	0.7	-0.010000000000000009	-1.4084507042253533	fred
1674	2026-01-29	RATES.2S10S	0.71	0.010000000000000009	1.42857142857143	fred
1675	2026-01-30	RATES.2S10S	0.74	0.030000000000000027	4.2253521126760605	fred
1676	2026-02-02	RATES.2S10S	0.72	-0.020000000000000018	-2.7027027027027053	fred
1677	2026-02-03	RATES.2S10S	0.71	-0.010000000000000009	-1.3888888888888902	fred
1678	2026-02-04	RATES.2S10S	0.72	0.010000000000000009	1.4084507042253533	fred
1679	2026-02-05	RATES.2S10S	0.74	0.020000000000000018	2.7777777777777803	fred
1680	2026-02-06	RATES.2S10S	0.72	-0.020000000000000018	-2.7027027027027053	fred
803	2026-02-09	RATES.2S10S	0.74	\N	\N	fred
804	2026-02-10	RATES.2S10S	0.71	-0.030000000000000027	-4.054054054054058	fred
805	2026-02-11	RATES.2S10S	0.66	-0.04999999999999993	-7.042253521126751	fred
806	2026-02-12	RATES.2S10S	0.62	-0.040000000000000036	-6.060606060606066	fred
807	2026-02-13	RATES.2S10S	0.64	0.020000000000000018	3.225806451612906	fred
808	2026-02-17	RATES.2S10S	0.62	-0.020000000000000018	-3.1250000000000027	fred
809	2026-02-18	RATES.2S10S	0.62	0	0	fred
810	2026-02-19	RATES.2S10S	0.61	-0.010000000000000009	-1.612903225806453	fred
811	2026-02-20	RATES.2S10S	0.6	-0.010000000000000009	-1.6393442622950836	fred
812	2026-02-23	RATES.2S10S	0.6	0	0	fred
813	2026-02-24	RATES.2S10S	0.61	0.010000000000000009	1.6666666666666683	fred
814	2026-02-25	RATES.2S10S	0.6	-0.010000000000000009	-1.6393442622950836	fred
815	2026-02-26	RATES.2S10S	0.6	0	0	fred
816	2026-02-27	RATES.2S10S	0.59	-0.010000000000000009	-1.6666666666666683	fred
817	2026-03-02	RATES.2S10S	0.58	-0.010000000000000009	-1.6949152542372898	fred
818	2026-03-03	RATES.2S10S	0.55	-0.029999999999999916	-5.172413793103434	fred
819	2026-03-04	RATES.2S10S	0.55	0	0	fred
820	2026-03-05	RATES.2S10S	0.56	0.010000000000000009	1.8181818181818197	fred
821	2026-03-06	RATES.2S10S	0.59	0.029999999999999916	5.357142857142842	fred
1599	2025-12-09	RATES.REAL10Y	1.92	\N	\N	fred
1600	2025-12-10	RATES.REAL10Y	1.88	-0.040000000000000036	-2.0833333333333353	fred
1601	2025-12-11	RATES.REAL10Y	1.89	0.010000000000000009	0.5319148936170218	fred
1602	2025-12-12	RATES.REAL10Y	1.93	0.040000000000000036	2.1164021164021185	fred
1603	2025-12-15	RATES.REAL10Y	1.93	0	0	fred
1604	2025-12-16	RATES.REAL10Y	1.92	-0.010000000000000009	-0.5181347150259072	fred
1605	2025-12-17	RATES.REAL10Y	1.92	0	0	fred
1606	2025-12-18	RATES.REAL10Y	1.88	-0.040000000000000036	-2.0833333333333353	fred
1607	2025-12-19	RATES.REAL10Y	1.92	0.040000000000000036	2.1276595744680873	fred
1608	2025-12-22	RATES.REAL10Y	1.94	0.020000000000000018	1.0416666666666676	fred
1609	2025-12-23	RATES.REAL10Y	1.94	0	0	fred
1610	2025-12-24	RATES.REAL10Y	1.91	-0.030000000000000027	-1.546391752577321	fred
1611	2025-12-26	RATES.REAL10Y	1.91	0	0	fred
1612	2025-12-29	RATES.REAL10Y	1.9	-0.010000000000000009	-0.5235602094240842	fred
1613	2025-12-30	RATES.REAL10Y	1.9	0	0	fred
1614	2025-12-31	RATES.REAL10Y	1.93	0.030000000000000027	1.5789473684210542	fred
1615	2026-01-02	RATES.REAL10Y	1.94	0.010000000000000009	0.5181347150259072	fred
1616	2026-01-05	RATES.REAL10Y	1.91	-0.030000000000000027	-1.546391752577321	fred
1617	2026-01-06	RATES.REAL10Y	1.91	0	0	fred
1618	2026-01-07	RATES.REAL10Y	1.88	-0.030000000000000027	-1.5706806282722527	fred
1619	2026-01-08	RATES.REAL10Y	1.92	0.040000000000000036	2.1276595744680873	fred
1620	2026-01-09	RATES.REAL10Y	1.9	-0.020000000000000018	-1.0416666666666676	fred
1621	2026-01-12	RATES.REAL10Y	1.9	0	0	fred
1622	2026-01-13	RATES.REAL10Y	1.88	-0.020000000000000018	-1.0526315789473695	fred
1623	2026-01-14	RATES.REAL10Y	1.86	-0.019999999999999796	-1.0638297872340317	fred
1624	2026-01-15	RATES.REAL10Y	1.88	0.019999999999999796	1.0752688172042901	fred
1625	2026-01-16	RATES.REAL10Y	1.91	0.030000000000000027	1.5957446808510654	fred
1626	2026-01-20	RATES.REAL10Y	1.97	0.06000000000000005	3.1413612565445055	fred
1627	2026-01-21	RATES.REAL10Y	1.92	-0.050000000000000044	-2.53807106598985	fred
1628	2026-01-22	RATES.REAL10Y	1.95	0.030000000000000027	1.5625000000000016	fred
1629	2026-01-23	RATES.REAL10Y	1.92	-0.030000000000000027	-1.5384615384615399	fred
1630	2026-01-26	RATES.REAL10Y	1.9	-0.020000000000000018	-1.0416666666666676	fred
1631	2026-01-27	RATES.REAL10Y	1.9	0	0	fred
1632	2026-01-28	RATES.REAL10Y	1.9	0	0	fred
1633	2026-01-29	RATES.REAL10Y	1.89	-0.010000000000000009	-0.5263157894736847	fred
1634	2026-01-30	RATES.REAL10Y	1.9	0.010000000000000009	0.5291005291005296	fred
1635	2026-02-02	RATES.REAL10Y	1.94	0.040000000000000036	2.105263157894739	fred
1636	2026-02-03	RATES.REAL10Y	1.92	-0.020000000000000018	-1.0309278350515474	fred
1637	2026-02-04	RATES.REAL10Y	1.94	0.020000000000000018	1.0416666666666676	fred
1638	2026-02-05	RATES.REAL10Y	1.89	-0.050000000000000044	-2.5773195876288684	fred
1639	2026-02-06	RATES.REAL10Y	1.88	-0.010000000000000009	-0.5291005291005296	fred
785	2026-02-09	RATES.REAL10Y	1.87	\N	\N	fred
786	2026-02-10	RATES.REAL10Y	1.84	-0.030000000000000027	-1.6042780748663115	fred
787	2026-02-11	RATES.REAL10Y	1.86	0.020000000000000018	1.0869565217391313	fred
788	2026-02-12	RATES.REAL10Y	1.8	-0.06000000000000005	-3.225806451612906	fred
789	2026-02-13	RATES.REAL10Y	1.77	-0.030000000000000027	-1.666666666666668	fred
790	2026-02-17	RATES.REAL10Y	1.79	0.020000000000000018	1.1299435028248597	fred
791	2026-02-18	RATES.REAL10Y	1.8	0.010000000000000009	0.5586592178770955	fred
792	2026-02-19	RATES.REAL10Y	1.79	-0.010000000000000009	-0.555555555555556	fred
793	2026-02-20	RATES.REAL10Y	1.8	0.010000000000000009	0.5586592178770955	fred
794	2026-02-23	RATES.REAL10Y	1.77	-0.030000000000000027	-1.666666666666668	fred
795	2026-02-24	RATES.REAL10Y	1.78	0.010000000000000009	0.5649717514124298	fred
796	2026-02-25	RATES.REAL10Y	1.77	-0.010000000000000009	-0.5617977528089892	fred
797	2026-02-26	RATES.REAL10Y	1.74	-0.030000000000000027	-1.6949152542372896	fred
798	2026-02-27	RATES.REAL10Y	1.72	-0.020000000000000018	-1.1494252873563229	fred
799	2026-03-02	RATES.REAL10Y	1.76	0.040000000000000036	2.325581395348839	fred
800	2026-03-03	RATES.REAL10Y	1.77	0.010000000000000009	0.5681818181818187	fred
801	2026-03-04	RATES.REAL10Y	1.8	0.030000000000000027	1.6949152542372896	fred
802	2026-03-05	RATES.REAL10Y	1.82	0.020000000000000018	1.111111111111112	fred
1724	2025-12-09	RATES.BREAKEVEN	2.26	\N	\N	fred
1725	2025-12-10	RATES.BREAKEVEN	2.25	-0.009999999999999787	-0.4424778761061853	fred
1726	2025-12-11	RATES.BREAKEVEN	2.25	0	0	fred
1727	2025-12-12	RATES.BREAKEVEN	2.26	0.009999999999999787	0.444444444444435	fred
1728	2025-12-15	RATES.BREAKEVEN	2.25	-0.009999999999999787	-0.4424778761061853	fred
1729	2025-12-16	RATES.BREAKEVEN	2.23	-0.020000000000000018	-0.8888888888888897	fred
1730	2025-12-17	RATES.BREAKEVEN	2.24	0.010000000000000231	0.44843049327355294	fred
1731	2025-12-18	RATES.BREAKEVEN	2.24	0	0	fred
1732	2025-12-19	RATES.BREAKEVEN	2.24	0	0	fred
1733	2025-12-22	RATES.BREAKEVEN	2.23	-0.010000000000000231	-0.4464285714285817	fred
1734	2025-12-23	RATES.BREAKEVEN	2.24	0.010000000000000231	0.44843049327355294	fred
1735	2025-12-24	RATES.BREAKEVEN	2.24	0	0	fred
1736	2025-12-26	RATES.BREAKEVEN	2.23	-0.010000000000000231	-0.4464285714285817	fred
1737	2025-12-29	RATES.BREAKEVEN	2.22	-0.009999999999999787	-0.44843049327353307	fred
1738	2025-12-30	RATES.BREAKEVEN	2.24	0.020000000000000018	0.9009009009009016	fred
1739	2025-12-31	RATES.BREAKEVEN	2.25	0.009999999999999787	0.44642857142856185	fred
1740	2026-01-02	RATES.BREAKEVEN	2.25	0	0	fred
1741	2026-01-05	RATES.BREAKEVEN	2.26	0.009999999999999787	0.444444444444435	fred
1742	2026-01-06	RATES.BREAKEVEN	2.27	0.010000000000000231	0.4424778761062049	fred
1743	2026-01-07	RATES.BREAKEVEN	2.27	0	0	fred
1744	2026-01-08	RATES.BREAKEVEN	2.27	0	0	fred
1745	2026-01-09	RATES.BREAKEVEN	2.28	0.009999999999999787	0.4405286343612241	fred
1746	2026-01-12	RATES.BREAKEVEN	2.29	0.010000000000000231	0.43859649122808037	fred
1747	2026-01-13	RATES.BREAKEVEN	2.3	0.009999999999999787	0.4366812227074143	fred
1748	2026-01-14	RATES.BREAKEVEN	2.29	-0.009999999999999787	-0.43478260869564295	fred
1749	2026-01-15	RATES.BREAKEVEN	2.29	0	0	fred
1750	2026-01-16	RATES.BREAKEVEN	2.33	0.040000000000000036	1.746724890829696	fred
1751	2026-01-20	RATES.BREAKEVEN	2.33	0	0	fred
1752	2026-01-21	RATES.BREAKEVEN	2.34	0.009999999999999787	0.42918454935621403	fred
1753	2026-01-22	RATES.BREAKEVEN	2.31	-0.029999999999999805	-1.2820512820512737	fred
1754	2026-01-23	RATES.BREAKEVEN	2.32	0.009999999999999787	0.4329004329004237	fred
1755	2026-01-26	RATES.BREAKEVEN	2.32	0	0	fred
1756	2026-01-27	RATES.BREAKEVEN	2.34	0.020000000000000018	0.8620689655172422	fred
1757	2026-01-28	RATES.BREAKEVEN	2.36	0.020000000000000018	0.8547008547008556	fred
1758	2026-01-29	RATES.BREAKEVEN	2.35	-0.009999999999999787	-0.423728813559313	fred
1759	2026-01-30	RATES.BREAKEVEN	2.36	0.009999999999999787	0.4255319148936079	fred
1760	2026-02-02	RATES.BREAKEVEN	2.35	-0.009999999999999787	-0.423728813559313	fred
1761	2026-02-03	RATES.BREAKEVEN	2.36	0.009999999999999787	0.4255319148936079	fred
1762	2026-02-04	RATES.BREAKEVEN	2.35	-0.009999999999999787	-0.423728813559313	fred
1763	2026-02-05	RATES.BREAKEVEN	2.32	-0.03000000000000025	-1.2765957446808616	fred
1764	2026-02-06	RATES.BREAKEVEN	2.34	0.020000000000000018	0.8620689655172422	fred
843	2026-02-09	RATES.BREAKEVEN	2.35	\N	\N	fred
844	2026-02-10	RATES.BREAKEVEN	2.32	-0.03000000000000025	-1.2765957446808616	fred
845	2026-02-11	RATES.BREAKEVEN	2.32	0	0	fred
846	2026-02-12	RATES.BREAKEVEN	2.29	-0.029999999999999805	-1.2931034482758537	fred
847	2026-02-13	RATES.BREAKEVEN	2.27	-0.020000000000000018	-0.873362445414848	fred
848	2026-02-17	RATES.BREAKEVEN	2.26	-0.010000000000000231	-0.4405286343612437	fred
849	2026-02-18	RATES.BREAKEVEN	2.29	0.03000000000000025	1.3274336283185952	fred
850	2026-02-19	RATES.BREAKEVEN	2.29	0	0	fred
851	2026-02-20	RATES.BREAKEVEN	2.28	-0.010000000000000231	-0.43668122270743365	fred
852	2026-02-23	RATES.BREAKEVEN	2.26	-0.020000000000000018	-0.8771929824561412	fred
3165	2025-12-10	RATES.US3M	3.69	\N	\N	fred
853	2026-02-24	RATES.BREAKEVEN	2.26	0	0	fred
854	2026-02-25	RATES.BREAKEVEN	2.28	0.020000000000000018	0.8849557522123902	fred
855	2026-02-26	RATES.BREAKEVEN	2.28	0	0	fred
856	2026-02-27	RATES.BREAKEVEN	2.25	-0.029999999999999805	-1.315789473684202	fred
857	2026-03-02	RATES.BREAKEVEN	2.29	0.040000000000000036	1.7777777777777795	fred
858	2026-03-03	RATES.BREAKEVEN	2.29	0	0	fred
859	2026-03-04	RATES.BREAKEVEN	2.29	0	0	fred
860	2026-03-05	RATES.BREAKEVEN	2.31	0.020000000000000018	0.873362445414848	fred
861	2026-03-06	RATES.BREAKEVEN	2.35	0.040000000000000036	1.7316017316017331	fred
1681	2025-12-09	CREDIT.HY_OAS	2.89	\N	\N	fred
1682	2025-12-10	CREDIT.HY_OAS	2.91	0.020000000000000018	0.6920415224913501	fred
1683	2025-12-11	CREDIT.HY_OAS	2.88	-0.03000000000000025	-1.030927835051555	fred
1684	2025-12-12	CREDIT.HY_OAS	2.91	0.03000000000000025	1.0416666666666754	fred
1685	2025-12-15	CREDIT.HY_OAS	2.91	0	0	fred
1686	2025-12-16	CREDIT.HY_OAS	2.98	0.06999999999999984	2.405498281786936	fred
1687	2025-12-17	CREDIT.HY_OAS	2.99	0.010000000000000231	0.33557046979866545	fred
1688	2025-12-18	CREDIT.HY_OAS	2.95	-0.040000000000000036	-1.3377926421404693	fred
1689	2025-12-19	CREDIT.HY_OAS	2.9	-0.050000000000000266	-1.6949152542372972	fred
1690	2025-12-22	CREDIT.HY_OAS	2.88	-0.020000000000000018	-0.6896551724137937	fred
1691	2025-12-23	CREDIT.HY_OAS	2.83	-0.04999999999999982	-1.736111111111105	fred
1692	2025-12-24	CREDIT.HY_OAS	2.84	0.009999999999999787	0.3533568904593564	fred
1693	2025-12-26	CREDIT.HY_OAS	2.86	0.020000000000000018	0.7042253521126767	fred
1694	2025-12-29	CREDIT.HY_OAS	2.87	0.010000000000000231	0.34965034965035774	fred
1695	2025-12-30	CREDIT.HY_OAS	2.84	-0.03000000000000025	-1.0452961672473955	fred
1696	2025-12-31	CREDIT.HY_OAS	2.81	-0.029999999999999805	-1.0563380281690073	fred
1697	2026-01-02	CREDIT.HY_OAS	2.83	0.020000000000000018	0.7117437722419935	fred
1698	2026-01-05	CREDIT.HY_OAS	2.81	-0.020000000000000018	-0.7067137809187285	fred
1699	2026-01-06	CREDIT.HY_OAS	2.79	-0.020000000000000018	-0.7117437722419935	fred
1700	2026-01-07	CREDIT.HY_OAS	2.79	0	0	fred
1701	2026-01-08	CREDIT.HY_OAS	2.76	-0.03000000000000025	-1.07526881720431	fred
1702	2026-01-09	CREDIT.HY_OAS	2.74	-0.019999999999999574	-0.7246376811594049	fred
1703	2026-01-12	CREDIT.HY_OAS	2.74	0	0	fred
1704	2026-01-13	CREDIT.HY_OAS	2.75	0.009999999999999787	0.3649635036496272	fred
1705	2026-01-14	CREDIT.HY_OAS	2.76	0.009999999999999787	0.3636363636363559	fred
1706	2026-01-15	CREDIT.HY_OAS	2.71	-0.04999999999999982	-1.8115942028985443	fred
1707	2026-01-16	CREDIT.HY_OAS	2.65	-0.06000000000000005	-2.214022140221404	fred
1708	2026-01-19	CREDIT.HY_OAS	2.65	0	0	fred
1709	2026-01-20	CREDIT.HY_OAS	2.73	0.08000000000000007	3.0188679245283048	fred
1710	2026-01-21	CREDIT.HY_OAS	2.69	-0.040000000000000036	-1.4652014652014664	fred
1711	2026-01-22	CREDIT.HY_OAS	2.64	-0.04999999999999982	-1.8587360594795472	fred
1712	2026-01-23	CREDIT.HY_OAS	2.68	0.040000000000000036	1.5151515151515165	fred
1713	2026-01-26	CREDIT.HY_OAS	2.69	0.009999999999999787	0.373134328358201	fred
1714	2026-01-27	CREDIT.HY_OAS	2.71	0.020000000000000018	0.7434944237918223	fred
1715	2026-01-28	CREDIT.HY_OAS	2.72	0.010000000000000231	0.3690036900369089	fred
1716	2026-01-29	CREDIT.HY_OAS	2.77	0.04999999999999982	1.8382352941176403	fred
1717	2026-01-30	CREDIT.HY_OAS	2.8	0.029999999999999805	1.0830324909747222	fred
1718	2026-01-31	CREDIT.HY_OAS	2.88	0.08000000000000007	2.85714285714286	fred
1719	2026-02-02	CREDIT.HY_OAS	2.81	-0.06999999999999984	-2.43055555555555	fred
1720	2026-02-03	CREDIT.HY_OAS	2.85	0.040000000000000036	1.423487544483987	fred
1721	2026-02-04	CREDIT.HY_OAS	2.86	0.009999999999999787	0.3508771929824486	fred
1722	2026-02-05	CREDIT.HY_OAS	2.97	0.11000000000000032	3.8461538461538574	fred
1723	2026-02-06	CREDIT.HY_OAS	2.87	-0.10000000000000009	-3.36700336700337	fred
822	2026-02-09	CREDIT.HY_OAS	2.84	\N	\N	fred
823	2026-02-10	CREDIT.HY_OAS	2.86	0.020000000000000018	0.7042253521126767	fred
824	2026-02-11	CREDIT.HY_OAS	2.84	-0.020000000000000018	-0.6993006993006999	fred
825	2026-02-12	CREDIT.HY_OAS	2.92	0.08000000000000007	2.8169014084507067	fred
826	2026-02-13	CREDIT.HY_OAS	2.95	0.03000000000000025	1.0273972602739811	fred
827	2026-02-16	CREDIT.HY_OAS	2.94	-0.010000000000000231	-0.33898305084746544	fred
828	2026-02-17	CREDIT.HY_OAS	2.94	0	0	fred
829	2026-02-18	CREDIT.HY_OAS	2.86	-0.08000000000000007	-2.7210884353741522	fred
830	2026-02-19	CREDIT.HY_OAS	2.88	0.020000000000000018	0.6993006993006999	fred
831	2026-02-20	CREDIT.HY_OAS	2.86	-0.020000000000000018	-0.6944444444444451	fred
832	2026-02-23	CREDIT.HY_OAS	2.95	0.0900000000000003	3.1468531468531578	fred
833	2026-02-24	CREDIT.HY_OAS	2.97	0.020000000000000018	0.6779661016949158	fred
834	2026-02-25	CREDIT.HY_OAS	2.94	-0.03000000000000025	-1.0101010101010184	fred
835	2026-02-26	CREDIT.HY_OAS	2.98	0.040000000000000036	1.3605442176870761	fred
836	2026-02-27	CREDIT.HY_OAS	3.1	0.1200000000000001	4.026845637583897	fred
837	2026-02-28	CREDIT.HY_OAS	3.12	0.020000000000000018	0.6451612903225812	fred
838	2026-03-02	CREDIT.HY_OAS	3.03	-0.0900000000000003	-2.8846153846153944	fred
839	2026-03-03	CREDIT.HY_OAS	3.08	0.050000000000000266	1.650165016501659	fred
840	2026-03-04	CREDIT.HY_OAS	2.97	-0.10999999999999988	-3.571428571428567	fred
841	2026-03-05	CREDIT.HY_OAS	3	0.029999999999999805	1.0101010101010035	fred
842	2026-03-06	CREDIT.HY_OAS	3.13	0.1299999999999999	4.3333333333333295	fred
1767	2025-12-01	MACRO.CPI	326.031	\N	\N	fred
1768	2026-01-01	MACRO.CPI	326.588	0.5570000000000164	0.1708426499320667	fred
1765	2025-12-01	MACRO.UNRATE	4.4	\N	\N	fred
1766	2026-01-01	MACRO.UNRATE	4.3	-0.10000000000000053	-2.2727272727272845	fred
862	2026-02-01	MACRO.UNRATE	4.4	\N	\N	fred
5593	2025-02-21	EQ.LVMH	685.9495	6.7384033203125	0.9920926080105533	yfinance_direct
5594	2025-02-24	EQ.LVMH	675.8907	-10.058837890625	-1.4664107984297328	yfinance_direct
5595	2025-02-25	EQ.LVMH	668.1758	-7.71490478515625	-1.1414426836405558	yfinance_direct
5596	2025-02-26	EQ.LVMH	683.8987	15.72296142578125	2.353117527900709	yfinance_direct
5597	2025-02-27	EQ.LVMH	676.8673	-7.03143310546875	-1.0281394988325299	yfinance_direct
5598	2025-02-28	EQ.LVMH	678.6252	1.7579345703125	0.2597162760642804	yfinance_direct
5599	2025-03-03	EQ.LVMH	674.6212	-4.0040283203125	-0.5900205385644015	yfinance_direct
5600	2025-03-04	EQ.LVMH	651.7693	-22.8519287109375	-3.3873717836090385	yfinance_direct
5601	2025-03-05	EQ.LVMH	648.7418	-3.0274658203125	-0.4644996136193287	yfinance_direct
5602	2025-03-06	EQ.LVMH	637.7065	-11.0352783203125	-1.70102773679446	yfinance_direct
5603	2025-03-07	EQ.LVMH	619.8351	-17.8714599609375	-2.802458302801712	yfinance_direct
5604	2025-03-10	EQ.LVMH	615.5381	-4.2969970703125	-0.6932484443218164	yfinance_direct
5605	2025-03-11	EQ.LVMH	606.2606	-9.2774658203125	-1.5072123126520083	yfinance_direct
5606	2025-03-12	EQ.LVMH	597.4714	-8.78924560546875	-1.4497470747431735	yfinance_direct
5607	2025-03-13	EQ.LVMH	590.8307	-6.64068603515625	-1.1114651376533857	yfinance_direct
5608	2025-03-14	EQ.LVMH	590.9283	0.09765625	0.016528635344213997	yfinance_direct
5609	2025-03-17	EQ.LVMH	595.4207	4.4923095703125	0.7602122339200373	yfinance_direct
5610	2025-03-18	EQ.LVMH	595.7136	0.29296875	0.049203659276140364	yfinance_direct
5611	2025-03-19	EQ.LVMH	596.2995	0.58587646484375	0.09834867664217394	yfinance_direct
5612	2025-03-20	EQ.LVMH	590.3424	-5.95709228515625	-0.9990101098582557	yfinance_direct
3166	2025-12-11	RATES.US3M	3.66	-0.029999999999999805	-0.8130081300812956	fred
3167	2025-12-12	RATES.US3M	3.63	-0.03000000000000025	-0.8196721311475478	fred
3168	2025-12-15	RATES.US3M	3.65	0.020000000000000018	0.5509641873278242	fred
3169	2025-12-16	RATES.US3M	3.64	-0.009999999999999787	-0.2739726027397202	fred
3170	2025-12-17	RATES.US3M	3.64	0	0	fred
3171	2025-12-18	RATES.US3M	3.62	-0.020000000000000018	-0.5494505494505499	fred
3172	2025-12-19	RATES.US3M	3.62	0	0	fred
3173	2025-12-22	RATES.US3M	3.64	0.020000000000000018	0.5524861878453043	fred
3174	2025-12-23	RATES.US3M	3.65	0.009999999999999787	0.27472527472526886	fred
3175	2025-12-24	RATES.US3M	3.69	0.040000000000000036	1.0958904109589052	fred
3176	2025-12-26	RATES.US3M	3.64	-0.04999999999999982	-1.3550135501354965	fred
3177	2025-12-29	RATES.US3M	3.68	0.040000000000000036	1.0989010989010999	fred
3178	2025-12-30	RATES.US3M	3.65	-0.03000000000000025	-0.8152173913043546	fred
3179	2025-12-31	RATES.US3M	3.67	0.020000000000000018	0.5479452054794526	fred
3180	2026-01-02	RATES.US3M	3.65	-0.020000000000000018	-0.5449591280653956	fred
3181	2026-01-05	RATES.US3M	3.64	-0.009999999999999787	-0.2739726027397202	fred
3182	2026-01-06	RATES.US3M	3.63	-0.010000000000000231	-0.2747252747252811	fred
3183	2026-01-07	RATES.US3M	3.62	-0.009999999999999787	-0.27548209366390597	fred
3184	2026-01-08	RATES.US3M	3.62	0	0	fred
3185	2026-01-09	RATES.US3M	3.62	0	0	fred
3186	2026-01-12	RATES.US3M	3.67	0.04999999999999982	1.3812154696132548	fred
3187	2026-01-13	RATES.US3M	3.67	0	0	fred
3188	2026-01-14	RATES.US3M	3.67	0	0	fred
3189	2026-01-15	RATES.US3M	3.68	0.010000000000000231	0.27247956403270385	fred
3190	2026-01-16	RATES.US3M	3.67	-0.010000000000000231	-0.27173913043478887	fred
3191	2026-01-20	RATES.US3M	3.7	0.03000000000000025	0.8174386920980994	fred
3192	2026-01-21	RATES.US3M	3.7	0	0	fred
3193	2026-01-22	RATES.US3M	3.71	0.009999999999999787	0.2702702702702645	fred
3194	2026-01-23	RATES.US3M	3.7	-0.009999999999999787	-0.2695417789757355	fred
3195	2026-01-26	RATES.US3M	3.67	-0.03000000000000025	-0.8108108108108175	fred
3196	2026-01-27	RATES.US3M	3.67	0	0	fred
3197	2026-01-28	RATES.US3M	3.68	0.010000000000000231	0.27247956403270385	fred
3198	2026-01-29	RATES.US3M	3.67	-0.010000000000000231	-0.27173913043478887	fred
3199	2026-01-30	RATES.US3M	3.67	0	0	fred
3200	2026-02-02	RATES.US3M	3.69	0.020000000000000018	0.5449591280653956	fred
3201	2026-02-03	RATES.US3M	3.69	0	0	fred
3202	2026-02-04	RATES.US3M	3.69	0	0	fred
3203	2026-02-05	RATES.US3M	3.67	-0.020000000000000018	-0.542005420054201	fred
3204	2026-02-06	RATES.US3M	3.68	0.010000000000000231	0.27247956403270385	fred
3205	2026-02-09	RATES.US3M	3.69	0.009999999999999787	0.2717391304347768	fred
3206	2026-02-10	RATES.US3M	3.69	0	0	fred
3207	2026-02-11	RATES.US3M	3.7	0.010000000000000231	0.2710027100271065	fred
3208	2026-02-12	RATES.US3M	3.7	0	0	fred
3209	2026-02-13	RATES.US3M	3.68	-0.020000000000000018	-0.540540540540541	fred
3210	2026-02-17	RATES.US3M	3.69	0.009999999999999787	0.2717391304347768	fred
3211	2026-02-18	RATES.US3M	3.7	0.010000000000000231	0.2710027100271065	fred
3212	2026-02-19	RATES.US3M	3.69	-0.010000000000000231	-0.2702702702702765	fred
3213	2026-02-20	RATES.US3M	3.69	0	0	fred
3214	2026-02-23	RATES.US3M	3.69	0	0	fred
3215	2026-02-24	RATES.US3M	3.69	0	0	fred
3216	2026-02-25	RATES.US3M	3.69	0	0	fred
3217	2026-02-26	RATES.US3M	3.68	-0.009999999999999787	-0.2710027100270945	fred
3218	2026-02-27	RATES.US3M	3.67	-0.010000000000000231	-0.27173913043478887	fred
3219	2026-03-02	RATES.US3M	3.72	0.050000000000000266	1.362397820163495	fred
3220	2026-03-03	RATES.US3M	3.71	-0.010000000000000231	-0.26881720430108147	fred
3221	2026-03-04	RATES.US3M	3.71	0	0	fred
3222	2026-03-05	RATES.US3M	3.7	-0.009999999999999787	-0.2695417789757355	fred
3223	2026-03-06	RATES.US3M	3.69	-0.010000000000000231	-0.2702702702702765	fred
3224	2026-03-06	RATES.US2Y	3.56	-0.009999999999999787	-0.28011204481792124	fred
3225	2025-12-10	RATES.US5Y	3.72	\N	\N	fred
3226	2025-12-11	RATES.US5Y	3.72	0	0	fred
3227	2025-12-12	RATES.US5Y	3.75	0.029999999999999805	0.8064516129032205	fred
3228	2025-12-15	RATES.US5Y	3.73	-0.020000000000000018	-0.5333333333333338	fred
3229	2025-12-16	RATES.US5Y	3.69	-0.040000000000000036	-1.0723860589812342	fred
3230	2025-12-17	RATES.US5Y	3.7	0.010000000000000231	0.2710027100271065	fred
3231	2025-12-18	RATES.US5Y	3.66	-0.040000000000000036	-1.081081081081082	fred
3232	2025-12-19	RATES.US5Y	3.7	0.040000000000000036	1.092896174863389	fred
3233	2025-12-22	RATES.US5Y	3.71	0.009999999999999787	0.2702702702702645	fred
3234	2025-12-23	RATES.US5Y	3.72	0.010000000000000231	0.2695417789757475	fred
3235	2025-12-24	RATES.US5Y	3.7	-0.020000000000000018	-0.537634408602151	fred
3236	2025-12-26	RATES.US5Y	3.68	-0.020000000000000018	-0.540540540540541	fred
3237	2025-12-29	RATES.US5Y	3.67	-0.010000000000000231	-0.27173913043478887	fred
3238	2025-12-30	RATES.US5Y	3.68	0.010000000000000231	0.27247956403270385	fred
3239	2025-12-31	RATES.US5Y	3.73	0.04999999999999982	1.3586956521739082	fred
3240	2026-01-02	RATES.US5Y	3.74	0.010000000000000231	0.2680965147453145	fred
3241	2026-01-05	RATES.US5Y	3.71	-0.03000000000000025	-0.8021390374331617	fred
3242	2026-01-06	RATES.US5Y	3.72	0.010000000000000231	0.2695417789757475	fred
3243	2026-01-07	RATES.US5Y	3.7	-0.020000000000000018	-0.537634408602151	fred
3244	2026-01-08	RATES.US5Y	3.74	0.040000000000000036	1.081081081081082	fred
3245	2026-01-09	RATES.US5Y	3.75	0.009999999999999787	0.2673796791443793	fred
3246	2026-01-12	RATES.US5Y	3.77	0.020000000000000018	0.5333333333333338	fred
3247	2026-01-13	RATES.US5Y	3.75	-0.020000000000000018	-0.5305039787798413	fred
3248	2026-01-14	RATES.US5Y	3.72	-0.029999999999999805	-0.7999999999999948	fred
3249	2026-01-15	RATES.US5Y	3.77	0.04999999999999982	1.3440860215053716	fred
3250	2026-01-16	RATES.US5Y	3.82	0.04999999999999982	1.3262599469495975	fred
3251	2026-01-20	RATES.US5Y	3.86	0.040000000000000036	1.0471204188481684	fred
3252	2026-01-21	RATES.US5Y	3.83	-0.029999999999999805	-0.7772020725388551	fred
3253	2026-01-22	RATES.US5Y	3.85	0.020000000000000018	0.5221932114882512	fred
3254	2026-01-23	RATES.US5Y	3.84	-0.010000000000000231	-0.2597402597402657	fred
3255	2026-01-26	RATES.US5Y	3.82	-0.020000000000000018	-0.5208333333333338	fred
3256	2026-01-27	RATES.US5Y	3.81	-0.009999999999999787	-0.26178010471203633	fred
3257	2026-01-28	RATES.US5Y	3.83	0.020000000000000018	0.5249343832021002	fred
3258	2026-01-29	RATES.US5Y	3.8	-0.03000000000000025	-0.7832898172323824	fred
3259	2026-01-30	RATES.US5Y	3.79	-0.009999999999999787	-0.2631578947368365	fred
3260	2026-02-02	RATES.US5Y	3.83	0.040000000000000036	1.0554089709762542	fred
3261	2026-02-03	RATES.US5Y	3.83	0	0	fred
3262	2026-02-04	RATES.US5Y	3.83	0	0	fred
3263	2026-02-05	RATES.US5Y	3.74	-0.08999999999999986	-2.349869451697124	fred
3264	2026-02-06	RATES.US5Y	3.76	0.019999999999999574	0.5347593582887586	fred
3265	2026-02-09	RATES.US5Y	3.75	-0.009999999999999787	-0.26595744680850497	fred
3266	2026-02-10	RATES.US5Y	3.7	-0.04999999999999982	-1.3333333333333286	fred
3267	2026-02-11	RATES.US5Y	3.75	0.04999999999999982	1.3513513513513464	fred
3268	2026-02-12	RATES.US5Y	3.67	-0.08000000000000007	-2.133333333333335	fred
3269	2026-02-13	RATES.US5Y	3.61	-0.06000000000000005	-1.6348773841961868	fred
3270	2026-02-17	RATES.US5Y	3.63	0.020000000000000018	0.5540166204986154	fred
3271	2026-02-18	RATES.US5Y	3.66	0.03000000000000025	0.8264462809917424	fred
3272	2026-02-19	RATES.US5Y	3.65	-0.010000000000000231	-0.2732240437158533	fred
3273	2026-02-20	RATES.US5Y	3.65	0	0	fred
3274	2026-02-23	RATES.US5Y	3.59	-0.06000000000000005	-1.6438356164383576	fred
3275	2026-02-24	RATES.US5Y	3.61	0.020000000000000018	0.5571030640668528	fred
3276	2026-02-25	RATES.US5Y	3.61	0	0	fred
3277	2026-02-26	RATES.US5Y	3.57	-0.040000000000000036	-1.1080332409972309	fred
3278	2026-02-27	RATES.US5Y	3.51	-0.06000000000000005	-1.6806722689075646	fred
3279	2026-03-02	RATES.US5Y	3.62	0.11000000000000032	3.1339031339031433	fred
3280	2026-03-03	RATES.US5Y	3.63	0.009999999999999787	0.276243093922646	fred
3281	2026-03-04	RATES.US5Y	3.67	0.040000000000000036	1.1019283746556483	fred
3282	2026-03-05	RATES.US5Y	3.72	0.050000000000000266	1.362397820163495	fred
3283	2026-03-06	RATES.US5Y	3.72	0	0	fred
3284	2026-03-06	RATES.US10Y	4.15	0.020000000000000462	0.48426150121066497	fred
3285	2025-12-10	RATES.US30Y	4.78	\N	\N	fred
3286	2025-12-11	RATES.US30Y	4.79	0.009999999999999787	0.20920502092049761	fred
3287	2025-12-12	RATES.US30Y	4.85	0.05999999999999961	1.252609603340284	fred
3288	2025-12-15	RATES.US30Y	4.84	-0.009999999999999787	-0.2061855670103049	fred
3289	2025-12-16	RATES.US30Y	4.82	-0.019999999999999574	-0.41322314049585895	fred
3290	2025-12-17	RATES.US30Y	4.83	0.009999999999999787	0.20746887966804536	fred
3291	2025-12-18	RATES.US30Y	4.8	-0.03000000000000025	-0.6211180124223654	fred
3292	2025-12-19	RATES.US30Y	4.82	0.020000000000000462	0.4166666666666763	fred
3293	2025-12-22	RATES.US30Y	4.84	0.019999999999999574	0.41493775933609073	fred
3294	2025-12-23	RATES.US30Y	4.83	-0.009999999999999787	-0.20661157024792948	fred
3295	2025-12-24	RATES.US30Y	4.79	-0.040000000000000036	-0.828157349896481	fred
3296	2025-12-26	RATES.US30Y	4.81	0.019999999999999574	0.4175365344467552	fred
3297	2025-12-29	RATES.US30Y	4.8	-0.009999999999999787	-0.2079002079002035	fred
3298	2025-12-30	RATES.US30Y	4.81	0.009999999999999787	0.2083333333333289	fred
3299	2025-12-31	RATES.US30Y	4.84	0.03000000000000025	0.623700623700629	fred
3300	2026-01-02	RATES.US30Y	4.86	0.020000000000000462	0.41322314049587733	fred
3301	2026-01-05	RATES.US30Y	4.85	-0.010000000000000675	-0.20576131687244187	fred
3302	2026-01-06	RATES.US30Y	4.86	0.010000000000000675	0.2061855670103232	fred
3303	2026-01-07	RATES.US30Y	4.82	-0.040000000000000036	-0.8230452674897126	fred
3304	2026-01-08	RATES.US30Y	4.85	0.02999999999999936	0.6224066390041361	fred
3305	2026-01-09	RATES.US30Y	4.82	-0.02999999999999936	-0.6185567010309146	fred
3306	2026-01-12	RATES.US30Y	4.83	0.009999999999999787	0.20746887966804536	fred
3307	2026-01-13	RATES.US30Y	4.83	0	0	fred
3308	2026-01-14	RATES.US30Y	4.79	-0.040000000000000036	-0.828157349896481	fred
3309	2026-01-15	RATES.US30Y	4.79	0	0	fred
3310	2026-01-16	RATES.US30Y	4.83	0.040000000000000036	0.835073068893529	fred
3311	2026-01-20	RATES.US30Y	4.91	0.08000000000000007	1.656314699792962	fred
3312	2026-01-21	RATES.US30Y	4.87	-0.040000000000000036	-0.8146639511201637	fred
3313	2026-01-22	RATES.US30Y	4.84	-0.03000000000000025	-0.6160164271047279	fred
3314	2026-01-23	RATES.US30Y	4.82	-0.019999999999999574	-0.41322314049585895	fred
3315	2026-01-26	RATES.US30Y	4.8	-0.020000000000000462	-0.41493775933610916	fred
3316	2026-01-27	RATES.US30Y	4.83	0.03000000000000025	0.6250000000000052	fred
3317	2026-01-28	RATES.US30Y	4.85	0.019999999999999574	0.4140786749482313	fred
3318	2026-01-29	RATES.US30Y	4.85	0	0	fred
3319	2026-01-30	RATES.US30Y	4.87	0.020000000000000462	0.4123711340206281	fred
3320	2026-02-02	RATES.US30Y	4.9	0.03000000000000025	0.6160164271047279	fred
3321	2026-02-03	RATES.US30Y	4.9	0	0	fred
3322	2026-02-04	RATES.US30Y	4.91	0.009999999999999787	0.20408163265305687	fred
3323	2026-02-05	RATES.US30Y	4.85	-0.0600000000000005	-1.2219959266802545	fred
3324	2026-02-06	RATES.US30Y	4.85	0	0	fred
3325	2026-02-09	RATES.US30Y	4.85	0	0	fred
3326	2026-02-10	RATES.US30Y	4.78	-0.0699999999999994	-1.4432989690721525	fred
3327	2026-02-11	RATES.US30Y	4.82	0.040000000000000036	0.8368200836820091	fred
3328	2026-02-12	RATES.US30Y	4.72	-0.10000000000000053	-2.0746887966805088	fred
3329	2026-02-13	RATES.US30Y	4.69	-0.02999999999999936	-0.6355932203389696	fred
3330	2026-02-17	RATES.US30Y	4.68	-0.010000000000000675	-0.2132196162047052	fred
3331	2026-02-18	RATES.US30Y	4.71	0.03000000000000025	0.6410256410256464	fred
3332	2026-02-19	RATES.US30Y	4.7	-0.009999999999999787	-0.21231422505307404	fred
3333	2026-02-20	RATES.US30Y	4.72	0.019999999999999574	0.4255319148936079	fred
3334	2026-02-23	RATES.US30Y	4.7	-0.019999999999999574	-0.423728813559313	fred
3335	2026-02-24	RATES.US30Y	4.7	0	0	fred
3336	2026-02-25	RATES.US30Y	4.7	0	0	fred
3337	2026-02-26	RATES.US30Y	4.67	-0.03000000000000025	-0.6382978723404308	fred
3338	2026-02-27	RATES.US30Y	4.64	-0.03000000000000025	-0.6423982869379068	fred
3339	2026-03-02	RATES.US30Y	4.7	0.0600000000000005	1.293103448275873	fred
3340	2026-03-03	RATES.US30Y	4.7	0	0	fred
3341	2026-03-04	RATES.US30Y	4.72	0.019999999999999574	0.4255319148936079	fred
3342	2026-03-05	RATES.US30Y	4.74	0.020000000000000462	0.42372881355933184	fred
3343	2026-03-06	RATES.US30Y	4.77	0.02999999999999936	0.6329113924050498	fred
3344	2026-03-09	RATES.2S10S	0.56	-0.029999999999999916	-5.08474576271185	fred
3345	2026-03-06	RATES.REAL10Y	1.8	-0.020000000000000018	-1.0989010989010999	fred
3346	2025-12-10	RATES.REAL5Y	1.4	\N	\N	fred
3347	2025-12-11	RATES.REAL5Y	1.4	0	0	fred
3348	2025-12-12	RATES.REAL5Y	1.43	0.030000000000000027	2.142857142857145	fred
3349	2025-12-15	RATES.REAL5Y	1.44	0.010000000000000009	0.6993006993006999	fred
3350	2025-12-16	RATES.REAL5Y	1.44	0	0	fred
3351	2025-12-17	RATES.REAL5Y	1.44	0	0	fred
3352	2025-12-18	RATES.REAL5Y	1.4	-0.040000000000000036	-2.7777777777777803	fred
3353	2025-12-19	RATES.REAL5Y	1.43	0.030000000000000027	2.142857142857145	fred
3354	2025-12-22	RATES.REAL5Y	1.46	0.030000000000000027	2.0979020979020997	fred
3355	2025-12-23	RATES.REAL5Y	1.48	0.020000000000000018	1.3698630136986314	fred
3356	2025-12-24	RATES.REAL5Y	1.46	-0.020000000000000018	-1.3513513513513526	fred
3357	2025-12-26	RATES.REAL5Y	1.46	0	0	fred
3358	2025-12-29	RATES.REAL5Y	1.44	-0.020000000000000018	-1.3698630136986314	fred
3359	2025-12-30	RATES.REAL5Y	1.43	-0.010000000000000009	-0.6944444444444451	fred
3360	2025-12-31	RATES.REAL5Y	1.47	0.040000000000000036	2.7972027972027997	fred
3361	2026-01-02	RATES.REAL5Y	1.46	-0.010000000000000009	-0.6802721088435381	fred
3362	2026-01-05	RATES.REAL5Y	1.42	-0.040000000000000036	-2.739726027397263	fred
3363	2026-01-06	RATES.REAL5Y	1.42	0	0	fred
3364	2026-01-07	RATES.REAL5Y	1.4	-0.020000000000000018	-1.4084507042253533	fred
3365	2026-01-08	RATES.REAL5Y	1.43	0.030000000000000027	2.142857142857145	fred
3366	2026-01-09	RATES.REAL5Y	1.43	0	0	fred
3367	2026-01-12	RATES.REAL5Y	1.41	-0.020000000000000018	-1.3986013986013999	fred
3368	2026-01-13	RATES.REAL5Y	1.38	-0.030000000000000027	-2.1276595744680873	fred
3369	2026-01-14	RATES.REAL5Y	1.36	-0.019999999999999796	-1.449275362318826	fred
3370	2026-01-15	RATES.REAL5Y	1.41	0.04999999999999982	3.6764705882352806	fred
3371	2026-01-16	RATES.REAL5Y	1.43	0.020000000000000018	1.4184397163120581	fred
3372	2026-01-20	RATES.REAL5Y	1.46	0.030000000000000027	2.0979020979020997	fred
3373	2026-01-21	RATES.REAL5Y	1.41	-0.050000000000000044	-3.4246575342465784	fred
3374	2026-01-22	RATES.REAL5Y	1.43	0.020000000000000018	1.4184397163120581	fred
3375	2026-01-23	RATES.REAL5Y	1.38	-0.050000000000000044	-3.4965034965035	fred
3376	2026-01-26	RATES.REAL5Y	1.37	-0.009999999999999787	-0.7246376811594049	fred
3377	2026-01-27	RATES.REAL5Y	1.34	-0.030000000000000027	-2.189781021897812	fred
3378	2026-01-28	RATES.REAL5Y	1.33	-0.010000000000000009	-0.7462686567164185	fred
3379	2026-01-29	RATES.REAL5Y	1.28	-0.050000000000000044	-3.7593984962406046	fred
3380	2026-01-30	RATES.REAL5Y	1.26	-0.020000000000000018	-1.5625000000000013	fred
3381	2026-02-02	RATES.REAL5Y	1.31	0.050000000000000044	3.968253968253972	fred
3382	2026-02-03	RATES.REAL5Y	1.3	-0.010000000000000009	-0.7633587786259548	fred
3383	2026-02-04	RATES.REAL5Y	1.32	0.020000000000000018	1.5384615384615399	fred
3384	2026-02-05	RATES.REAL5Y	1.26	-0.06000000000000005	-4.545454545454549	fred
3385	2026-02-06	RATES.REAL5Y	1.26	0	0	fred
3386	2026-02-09	RATES.REAL5Y	1.25	-0.010000000000000009	-0.7936507936507944	fred
3387	2026-02-10	RATES.REAL5Y	1.23	-0.020000000000000018	-1.6000000000000014	fred
3388	2026-02-11	RATES.REAL5Y	1.26	0.030000000000000027	2.4390243902439046	fred
3389	2026-02-12	RATES.REAL5Y	1.22	-0.040000000000000036	-3.1746031746031775	fred
3390	2026-02-13	RATES.REAL5Y	1.19	-0.030000000000000027	-2.4590163934426252	fred
3391	2026-02-17	RATES.REAL5Y	1.24	0.050000000000000044	4.201680672268911	fred
3392	2026-02-18	RATES.REAL5Y	1.23	-0.010000000000000009	-0.8064516129032265	fred
3393	2026-02-19	RATES.REAL5Y	1.22	-0.010000000000000009	-0.8130081300813016	fred
3394	2026-02-20	RATES.REAL5Y	1.22	0	0	fred
3395	2026-02-23	RATES.REAL5Y	1.19	-0.030000000000000027	-2.4590163934426252	fred
3396	2026-02-24	RATES.REAL5Y	1.21	0.020000000000000018	1.6806722689075646	fred
3397	2026-02-25	RATES.REAL5Y	1.19	-0.020000000000000018	-1.6528925619834727	fred
3398	2026-02-26	RATES.REAL5Y	1.14	-0.050000000000000044	-4.201680672268911	fred
3399	2026-02-27	RATES.REAL5Y	1.11	-0.029999999999999805	-2.631578947368404	fred
3400	2026-03-02	RATES.REAL5Y	1.16	0.04999999999999982	4.504504504504488	fred
3401	2026-03-03	RATES.REAL5Y	1.17	0.010000000000000009	0.8620689655172422	fred
3402	2026-03-04	RATES.REAL5Y	1.21	0.040000000000000036	3.418803418803422	fred
3403	2026-03-05	RATES.REAL5Y	1.21	0	0	fred
3404	2026-03-06	RATES.REAL5Y	1.16	-0.050000000000000044	-4.132231404958682	fred
3405	2026-03-09	RATES.BREAKEVEN	2.34	-0.010000000000000231	-0.42553191489362685	fred
3406	2025-12-10	RATES.BREAKEVEN5Y	2.32	\N	\N	fred
3407	2025-12-11	RATES.BREAKEVEN5Y	2.32	0	0	fred
3408	2025-12-12	RATES.BREAKEVEN5Y	2.32	0	0	fred
3409	2025-12-15	RATES.BREAKEVEN5Y	2.29	-0.029999999999999805	-1.2931034482758537	fred
3410	2025-12-16	RATES.BREAKEVEN5Y	2.25	-0.040000000000000036	-1.746724890829696	fred
3411	2025-12-17	RATES.BREAKEVEN5Y	2.26	0.009999999999999787	0.444444444444435	fred
3412	2025-12-18	RATES.BREAKEVEN5Y	2.26	0	0	fred
3413	2025-12-19	RATES.BREAKEVEN5Y	2.27	0.010000000000000231	0.4424778761062049	fred
3414	2025-12-22	RATES.BREAKEVEN5Y	2.25	-0.020000000000000018	-0.8810572687224677	fred
3415	2025-12-23	RATES.BREAKEVEN5Y	2.24	-0.009999999999999787	-0.444444444444435	fred
3416	2025-12-24	RATES.BREAKEVEN5Y	2.24	0	0	fred
3417	2025-12-26	RATES.BREAKEVEN5Y	2.22	-0.020000000000000018	-0.8928571428571436	fred
3418	2025-12-29	RATES.BREAKEVEN5Y	2.23	0.009999999999999787	0.4504504504504408	fred
3419	2025-12-30	RATES.BREAKEVEN5Y	2.25	0.020000000000000018	0.896860986547086	fred
3420	2025-12-31	RATES.BREAKEVEN5Y	2.26	0.009999999999999787	0.444444444444435	fred
3421	2026-01-02	RATES.BREAKEVEN5Y	2.28	0.020000000000000018	0.8849557522123902	fred
3422	2026-01-05	RATES.BREAKEVEN5Y	2.29	0.010000000000000231	0.43859649122808037	fred
3423	2026-01-06	RATES.BREAKEVEN5Y	2.3	0.009999999999999787	0.4366812227074143	fred
3424	2026-01-07	RATES.BREAKEVEN5Y	2.3	0	0	fred
3425	2026-01-08	RATES.BREAKEVEN5Y	2.31	0.010000000000000231	0.43478260869566226	fred
3426	2026-01-09	RATES.BREAKEVEN5Y	2.32	0.009999999999999787	0.4329004329004237	fred
3427	2026-01-12	RATES.BREAKEVEN5Y	2.36	0.040000000000000036	1.7241379310344844	fred
3428	2026-01-13	RATES.BREAKEVEN5Y	2.37	0.010000000000000231	0.42372881355933184	fred
3429	2026-01-14	RATES.BREAKEVEN5Y	2.36	-0.010000000000000231	-0.4219409282700519	fred
3430	2026-01-15	RATES.BREAKEVEN5Y	2.36	0	0	fred
3431	2026-01-16	RATES.BREAKEVEN5Y	2.39	0.03000000000000025	1.2711864406779767	fred
3432	2026-01-20	RATES.BREAKEVEN5Y	2.4	0.009999999999999787	0.41841004184099523	fred
3433	2026-01-21	RATES.BREAKEVEN5Y	2.42	0.020000000000000018	0.8333333333333341	fred
3434	2026-01-22	RATES.BREAKEVEN5Y	2.42	0	0	fred
3435	2026-01-23	RATES.BREAKEVEN5Y	2.46	0.040000000000000036	1.6528925619834727	fred
3436	2026-01-26	RATES.BREAKEVEN5Y	2.45	-0.009999999999999787	-0.40650406504064174	fred
3437	2026-01-27	RATES.BREAKEVEN5Y	2.47	0.020000000000000018	0.8163265306122456	fred
3438	2026-01-28	RATES.BREAKEVEN5Y	2.5	0.029999999999999805	1.214574898785417	fred
3439	2026-01-29	RATES.BREAKEVEN5Y	2.52	0.020000000000000018	0.8000000000000007	fred
3440	2026-01-30	RATES.BREAKEVEN5Y	2.53	0.009999999999999787	0.39682539682538837	fred
3441	2026-02-02	RATES.BREAKEVEN5Y	2.52	-0.009999999999999787	-0.39525691699603904	fred
3442	2026-02-03	RATES.BREAKEVEN5Y	2.53	0.009999999999999787	0.39682539682538837	fred
3443	2026-02-04	RATES.BREAKEVEN5Y	2.51	-0.020000000000000018	-0.7905138339920956	fred
3444	2026-02-05	RATES.BREAKEVEN5Y	2.48	-0.029999999999999805	-1.1952191235059684	fred
3445	2026-02-06	RATES.BREAKEVEN5Y	2.5	0.020000000000000018	0.8064516129032265	fred
3446	2026-02-09	RATES.BREAKEVEN5Y	2.5	0	0	fred
3447	2026-02-10	RATES.BREAKEVEN5Y	2.47	-0.029999999999999805	-1.1999999999999922	fred
3448	2026-02-11	RATES.BREAKEVEN5Y	2.49	0.020000000000000018	0.809716599190284	fred
3449	2026-02-12	RATES.BREAKEVEN5Y	2.45	-0.040000000000000036	-1.6064257028112463	fred
3450	2026-02-13	RATES.BREAKEVEN5Y	2.42	-0.03000000000000025	-1.2244897959183774	fred
3451	2026-02-17	RATES.BREAKEVEN5Y	2.39	-0.029999999999999805	-1.2396694214875952	fred
4348	2024-03-19	EQ.AAPL	174.492	\N	\N	yfinance_direct
3452	2026-02-18	RATES.BREAKEVEN5Y	2.43	0.040000000000000036	1.6736401673640182	fred
3453	2026-02-19	RATES.BREAKEVEN5Y	2.43	0	0	fred
3454	2026-02-20	RATES.BREAKEVEN5Y	2.43	0	0	fred
3455	2026-02-23	RATES.BREAKEVEN5Y	2.4	-0.03000000000000025	-1.234567901234578	fred
3456	2026-02-24	RATES.BREAKEVEN5Y	2.4	0	0	fred
3457	2026-02-25	RATES.BREAKEVEN5Y	2.42	0.020000000000000018	0.8333333333333341	fred
3458	2026-02-26	RATES.BREAKEVEN5Y	2.43	0.010000000000000231	0.41322314049587733	fred
3459	2026-02-27	RATES.BREAKEVEN5Y	2.4	-0.03000000000000025	-1.234567901234578	fred
3460	2026-03-02	RATES.BREAKEVEN5Y	2.46	0.06000000000000005	2.500000000000002	fred
3461	2026-03-03	RATES.BREAKEVEN5Y	2.46	0	0	fred
3462	2026-03-04	RATES.BREAKEVEN5Y	2.46	0	0	fred
3463	2026-03-05	RATES.BREAKEVEN5Y	2.51	0.04999999999999982	2.0325203252032447	fred
3464	2026-03-06	RATES.BREAKEVEN5Y	2.56	0.050000000000000266	1.992031872509971	fred
3465	2026-03-09	RATES.BREAKEVEN5Y	2.56	0	0	fred
3466	2025-12-10	CREDIT.IG_OAS	0.78	\N	\N	fred
3467	2025-12-11	CREDIT.IG_OAS	0.78	0	0	fred
3468	2025-12-12	CREDIT.IG_OAS	0.8	0.020000000000000018	2.564102564102566	fred
3469	2025-12-15	CREDIT.IG_OAS	0.8	0	0	fred
3470	2025-12-16	CREDIT.IG_OAS	0.81	0.010000000000000009	1.250000000000001	fred
3471	2025-12-17	CREDIT.IG_OAS	0.81	0	0	fred
3472	2025-12-18	CREDIT.IG_OAS	0.81	0	0	fred
3473	2025-12-19	CREDIT.IG_OAS	0.8	-0.010000000000000009	-1.234567901234569	fred
3474	2025-12-22	CREDIT.IG_OAS	0.8	0	0	fred
3475	2025-12-23	CREDIT.IG_OAS	0.79	-0.010000000000000009	-1.250000000000001	fred
3476	2025-12-24	CREDIT.IG_OAS	0.79	0	0	fred
3477	2025-12-26	CREDIT.IG_OAS	0.79	0	0	fred
3478	2025-12-29	CREDIT.IG_OAS	0.79	0	0	fred
3479	2025-12-30	CREDIT.IG_OAS	0.79	0	0	fred
3480	2025-12-31	CREDIT.IG_OAS	0.79	0	0	fred
3481	2026-01-02	CREDIT.IG_OAS	0.79	0	0	fred
3482	2026-01-05	CREDIT.IG_OAS	0.79	0	0	fred
3483	2026-01-06	CREDIT.IG_OAS	0.79	0	0	fred
3484	2026-01-07	CREDIT.IG_OAS	0.79	0	0	fred
3485	2026-01-08	CREDIT.IG_OAS	0.79	0	0	fred
3486	2026-01-09	CREDIT.IG_OAS	0.78	-0.010000000000000009	-1.2658227848101276	fred
3487	2026-01-12	CREDIT.IG_OAS	0.78	0	0	fred
3488	2026-01-13	CREDIT.IG_OAS	0.77	-0.010000000000000009	-1.282051282051283	fred
3489	2026-01-14	CREDIT.IG_OAS	0.77	0	0	fred
3490	2026-01-15	CREDIT.IG_OAS	0.76	-0.010000000000000009	-1.2987012987012998	fred
3491	2026-01-16	CREDIT.IG_OAS	0.75	-0.010000000000000009	-1.3157894736842117	fred
3492	2026-01-19	CREDIT.IG_OAS	0.75	0	0	fred
3493	2026-01-20	CREDIT.IG_OAS	0.75	0	0	fred
3494	2026-01-21	CREDIT.IG_OAS	0.74	-0.010000000000000009	-1.3333333333333346	fred
3495	2026-01-22	CREDIT.IG_OAS	0.73	-0.010000000000000009	-1.3513513513513526	fred
3496	2026-01-23	CREDIT.IG_OAS	0.73	0	0	fred
3497	2026-01-26	CREDIT.IG_OAS	0.74	0.010000000000000009	1.3698630136986314	fred
3498	2026-01-27	CREDIT.IG_OAS	0.73	-0.010000000000000009	-1.3513513513513526	fred
3499	2026-01-28	CREDIT.IG_OAS	0.73	0	0	fred
3500	2026-01-29	CREDIT.IG_OAS	0.74	0.010000000000000009	1.3698630136986314	fred
3501	2026-01-30	CREDIT.IG_OAS	0.74	0	0	fred
3502	2026-01-31	CREDIT.IG_OAS	0.75	0.010000000000000009	1.3513513513513526	fred
3503	2026-02-02	CREDIT.IG_OAS	0.74	-0.010000000000000009	-1.3333333333333346	fred
3504	2026-02-03	CREDIT.IG_OAS	0.74	0	0	fred
3505	2026-02-04	CREDIT.IG_OAS	0.75	0.010000000000000009	1.3513513513513526	fred
3506	2026-02-05	CREDIT.IG_OAS	0.76	0.010000000000000009	1.3333333333333346	fred
3507	2026-02-06	CREDIT.IG_OAS	0.76	0	0	fred
3508	2026-02-09	CREDIT.IG_OAS	0.76	0	0	fred
3509	2026-02-10	CREDIT.IG_OAS	0.77	0.010000000000000009	1.3157894736842117	fred
3510	2026-02-11	CREDIT.IG_OAS	0.77	0	0	fred
3511	2026-02-12	CREDIT.IG_OAS	0.78	0.010000000000000009	1.2987012987012998	fred
3512	2026-02-13	CREDIT.IG_OAS	0.79	0.010000000000000009	1.282051282051283	fred
3513	2026-02-16	CREDIT.IG_OAS	0.79	0	0	fred
3514	2026-02-17	CREDIT.IG_OAS	0.8	0.010000000000000009	1.2658227848101276	fred
3515	2026-02-18	CREDIT.IG_OAS	0.78	-0.020000000000000018	-2.500000000000002	fred
3516	2026-02-19	CREDIT.IG_OAS	0.79	0.010000000000000009	1.282051282051283	fred
3517	2026-02-20	CREDIT.IG_OAS	0.78	-0.010000000000000009	-1.2658227848101276	fred
3518	2026-02-23	CREDIT.IG_OAS	0.8	0.020000000000000018	2.564102564102566	fred
3519	2026-02-24	CREDIT.IG_OAS	0.81	0.010000000000000009	1.250000000000001	fred
3520	2026-02-25	CREDIT.IG_OAS	0.8	-0.010000000000000009	-1.234567901234569	fred
3521	2026-02-26	CREDIT.IG_OAS	0.82	0.019999999999999907	2.499999999999988	fred
3522	2026-02-27	CREDIT.IG_OAS	0.85	0.030000000000000027	3.658536585365857	fred
3523	2026-02-28	CREDIT.IG_OAS	0.86	0.010000000000000009	1.1764705882352953	fred
3524	2026-03-02	CREDIT.IG_OAS	0.85	-0.010000000000000009	-1.1627906976744196	fred
3525	2026-03-03	CREDIT.IG_OAS	0.84	-0.010000000000000009	-1.1764705882352953	fred
3526	2026-03-04	CREDIT.IG_OAS	0.82	-0.020000000000000018	-2.380952380952383	fred
3527	2026-03-05	CREDIT.IG_OAS	0.82	0	0	fred
3528	2026-03-06	CREDIT.IG_OAS	0.84	0.020000000000000018	2.4390243902439046	fred
3529	2026-03-09	CREDIT.IG_OAS	0.85	0.010000000000000009	1.1904761904761916	fred
3530	2026-03-09	CREDIT.HY_OAS	3.19	0.06000000000000005	1.9169329073482446	fred
3531	2025-12-01	MACRO.INDPRO	101.6296	\N	\N	fred
3532	2026-01-01	MACRO.INDPRO	102.3412	0.7116000000000042	0.7001897085101233	fred
3533	2025-12-01	MACRO.RETAIL	734685	\N	\N	fred
3534	2026-01-01	MACRO.RETAIL	733537	-1148	-0.15625744366633318	fred
3535	2025-12-01	MACRO.UMCSENT	52.9	\N	\N	fred
3536	2026-01-01	MACRO.UMCSENT	56.4	3.5	6.616257088846881	fred
3537	2025-12-01	MACRO.ISM_MFG	12580	\N	\N	fred
3538	2026-01-01	MACRO.ISM_MFG	12585	5	0.0397456279809221	fred
3539	2026-02-01	MACRO.ISM_MFG	12573	-12	-0.09535160905840286	fred
3540	2026-03-09	CM.WTI	94.7699966430664	3.8699951171875	4.257420299476811	yfinance
3541	2026-03-09	CM.BRENT	98.95999908447266	6.269996643066406	6.764479963230089	yfinance
3542	2026-03-09	CM.GOLD	5091.5	-54.60009765625	-1.0609995262454606	yfinance
3543	2026-03-09	CM.COPPER	5.80049991607666	0.04349994659423828	0.7556009523159526	yfinance
3544	2026-03-09	CM.NATGAS	3.119999885559082	-0.06600022315979004	-2.071570022209745	yfinance
3545	2026-03-09	FX.EURUSD	1.152325987815857	-0.008480548858642578	-0.7305738373026236	yfinance
3546	2026-03-09	FX.GBPUSD	1.3301055431365967	-0.00563204288482666	-0.42164291427944667	yfinance
3547	2026-03-09	FX.USDJPY	158.427001953125	0.89300537109375	0.566865178608443	yfinance
3548	2026-03-09	FX.DXY	99.18000030517578	0.19000244140625	0.19194105011269139	yfinance
3549	2026-03-09	EQ.XLE	56.31999969482422	-0.25	-0.441930354160623	yfinance
3550	2026-03-09	EQ.XLF	50.33000183105469	-0.23999786376953125	-0.4745854562346275	yfinance
3551	2026-03-09	EQ.XLU	46.849998474121094	0.10999679565429688	0.23533759457474002	yfinance
3552	2026-03-09	EQ.EEM	58.45000076293945	1.1300010681152344	1.9713905689662263	yfinance
3553	2026-03-09	EQ.GLD	472.5299987792969	-0.980010986328125	-0.20696732193965756	yfinance
3554	2026-03-09	EQ.SLV	78.26000213623047	2.3199996948242188	3.055042955278126	yfinance
3555	2026-03-09	EQ.XLK	139.75999450683594	2.470001220703125	1.7991123472162127	yfinance
3556	2026-03-09	EQ.XLV	154.25999450683594	1.55999755859375	1.021609423556513	yfinance
3557	2026-03-09	EQ.XLY	114.58999633789062	0.149993896484375	0.13106771520838834	yfinance
3558	2026-03-09	EQ.XLP	85.97000122070312	0.19000244140625	0.2214997016904917	yfinance
3559	2026-03-09	EQ.XLI	170.94000244140625	1	0.5884429714215115	yfinance
3560	2026-03-09	EQ.XLB	49.9900016784668	0.13000106811523438	0.2607321831605524	yfinance
3561	2026-03-09	FX.AUDUSD	0.6966199278831482	-0.004510045051574707	-0.6432537797089163	yfinance
3562	2026-03-09	FX.EURGBP	0.8662499785423279	-0.002740025520324707	-0.31531151192933127	yfinance
3563	2026-03-09	EQ.SPX	6795.990234375	55.97021484375	0.8304161513105205	yfinance
3564	2026-03-09	EQ.SX7E	5685.2001953125	-34.69970703125	-0.6066488509183817	yfinance
3565	2026-03-09	EQ.VIX	25.5	-3.989999771118164	-13.53000950181722	yfinance
3566	2026-03-09	EQ.SPY	678.27001953125	5.8900146484375	0.8759949144329562	yfinance
3567	2026-03-09	EQ.LQD	110.81999969482422	0.6599960327148438	0.5991249190034803	yfinance
3568	2026-03-09	EQ.HYG	80.16999816894531	0.4799957275390625	0.6023286646176093	yfinance
3569	2026-03-09	EQ.IEAC	119.05999755859375	-0.06000518798828125	-0.05037372952042096	yfinance
3570	2026-03-09	EQ.IWM	253.6199951171875	2.7299957275390625	1.088124570202259	yfinance
3571	2025-12-10	CM.IRON_ORE	106.66000366210938	\N	\N	yfinance
3572	2025-12-11	CM.IRON_ORE	106.20999908447266	-0.45000457763671875	-0.4219056461523275	yfinance
3573	2025-12-12	CM.IRON_ORE	106.05000305175781	-0.15999603271484375	-0.15064121466340766	yfinance
3574	2025-12-15	CM.IRON_ORE	106.0999984741211	0.04999542236328125	0.04714325405429826	yfinance
3575	2025-12-16	CM.IRON_ORE	106.36000061035156	0.26000213623046875	0.2450538548253476	yfinance
3576	2025-12-17	CM.IRON_ORE	106.61000061035156	0.25	0.23505076961767954	yfinance
3577	2025-12-18	CM.IRON_ORE	106.9000015258789	0.29000091552734375	0.27202036757064363	yfinance
3578	2025-12-19	CM.IRON_ORE	106.91999816894531	0.01999664306640625	0.018705933377901177	yfinance
3579	2025-12-22	CM.IRON_ORE	106.94000244140625	0.0200042724609375	0.018709570523307115	yfinance
3580	2025-12-23	CM.IRON_ORE	106.94999694824219	0.0099945068359375	0.009345901073280425	yfinance
3581	2025-12-24	CM.IRON_ORE	106.94000244140625	-0.0099945068359375	-0.009345027696236664	yfinance
3582	2025-12-26	CM.IRON_ORE	106.98999786376953	0.04999542236328125	0.046750908193287505	yfinance
3583	2025-12-29	CM.IRON_ORE	107.08000183105469	0.09000396728515625	0.08412372098535639	yfinance
3584	2025-12-30	CM.IRON_ORE	107.12999725341797	0.04999542236328125	0.04668978474819365	yfinance
3585	2025-12-31	CM.IRON_ORE	107.12999725341797	0	0	yfinance
3586	2026-01-02	CM.IRON_ORE	107.16999816894531	0.04000091552734375	0.03733866942301964	yfinance
3587	2026-01-05	CM.IRON_ORE	106.12999725341797	-1.0400009155273438	-0.9704216975798224	yfinance
3588	2026-01-06	CM.IRON_ORE	106.79000091552734	0.660003662109375	0.6218822945348934	yfinance
3589	2026-01-07	CM.IRON_ORE	108.4800033569336	1.69000244140625	1.5825474547407017	yfinance
3590	2026-01-08	CM.IRON_ORE	107.6500015258789	-0.8300018310546875	-0.7651196583426703	yfinance
3591	2026-01-09	CM.IRON_ORE	108.02999877929688	0.37999725341796875	0.35299326338292525	yfinance
3592	2026-01-12	CM.IRON_ORE	108.25	0.220001220703125	0.2036482673230267	yfinance
3593	2026-01-13	CM.IRON_ORE	107.9000015258789	-0.34999847412109375	-0.3233242255160219	yfinance
3594	2026-01-14	CM.IRON_ORE	107.68000030517578	-0.220001220703125	-0.20389362149393442	yfinance
3595	2026-01-15	CM.IRON_ORE	107.38999938964844	-0.29000091552734375	-0.2693173427799521	yfinance
3596	2026-01-16	CM.IRON_ORE	107.1500015258789	-0.23999786376953125	-0.22348250780664888	yfinance
3597	2026-01-20	CM.IRON_ORE	106.54000091552734	-0.6100006103515625	-0.5692959418243545	yfinance
3598	2026-01-21	CM.IRON_ORE	106.45999908447266	-0.0800018310546875	-0.07509088639685554	yfinance
3599	2026-01-22	CM.IRON_ORE	106.41999816894531	-0.04000091552734375	-0.03757365759096455	yfinance
3600	2026-01-23	CM.IRON_ORE	106.36000061035156	-0.05999755859375	-0.05637808647440669	yfinance
3601	2026-01-26	CM.IRON_ORE	106.1500015258789	-0.20999908447265625	-0.1974417856972238	yfinance
3602	2026-01-27	CM.IRON_ORE	106.02999877929688	-0.12000274658203125	-0.11305016001603646	yfinance
3603	2026-01-28	CM.IRON_ORE	105.8499984741211	-0.18000030517578125	-0.16976356431961745	yfinance
3604	2026-01-29	CM.IRON_ORE	105.7699966430664	-0.0800018310546875	-0.07558037997917107	yfinance
3605	2026-01-30	CM.IRON_ORE	105.62000274658203	-0.149993896484375	-0.14181138436691784	yfinance
3606	2026-02-02	CM.IRON_ORE	102.66000366210938	-2.9599990844726562	-2.802498586915105	yfinance
3607	2026-02-03	CM.IRON_ORE	102.16000366210938	-0.5	-0.48704459591261856	yfinance
3608	2026-02-04	CM.IRON_ORE	102.16999816894531	0.0099945068359375	0.009783189582680499	yfinance
3609	2026-02-05	CM.IRON_ORE	101.02999877929688	-1.1399993896484375	-1.1157868357434713	yfinance
3610	2026-02-06	CM.IRON_ORE	100.11000061035156	-0.9199981689453125	-0.9106188063558	yfinance
3611	2026-02-09	CM.IRON_ORE	100.62999725341797	0.5199966430664062	0.5194252720967796	yfinance
3612	2026-02-10	CM.IRON_ORE	100.83999633789062	0.20999908447265625	0.20868437861904393	yfinance
3613	2026-02-11	CM.IRON_ORE	100.58999633789062	-0.25	-0.24791750206169189	yfinance
3614	2026-02-12	CM.IRON_ORE	100.37000274658203	-0.21999359130859375	-0.21870325014190872	yfinance
3615	2026-02-13	CM.IRON_ORE	99.66000366210938	-0.7099990844726562	-0.7073817525593665	yfinance
3616	2026-02-17	CM.IRON_ORE	99.73999786376953	0.07999420166015625	0.08026710688409291	yfinance
3617	2026-02-18	CM.IRON_ORE	99.73999786376953	0	0	yfinance
3618	2026-02-19	CM.IRON_ORE	99.61000061035156	-0.12999725341796875	-0.13033613014061446	yfinance
3619	2026-02-20	CM.IRON_ORE	99.33000183105469	-0.279998779296875	-0.28109504826945786	yfinance
3620	2026-02-23	CM.IRON_ORE	99.2699966430664	-0.06000518798828125	-0.06040993343616464	yfinance
3621	2026-02-24	CM.IRON_ORE	99.1500015258789	-0.1199951171875	-0.12087752719379301	yfinance
3622	2026-02-25	CM.IRON_ORE	99.06999969482422	-0.0800018310546875	-0.08068767506151416	yfinance
3623	2026-02-26	CM.IRON_ORE	99.02999877929688	-0.04000091552734375	-0.04037641632236075	yfinance
3624	2026-02-27	CM.IRON_ORE	99.05999755859375	0.029998779296875	0.030292618061857957	yfinance
3625	2026-03-02	CM.IRON_ORE	99.80999755859375	0.75	0.7571169175088832	yfinance
3626	2026-03-03	CM.IRON_ORE	99.56999969482422	-0.23999786376953125	-0.2404547336339126	yfinance
3627	2026-03-04	CM.IRON_ORE	100.05999755859375	0.48999786376953125	0.4921139552790437	yfinance
3628	2026-03-05	CM.IRON_ORE	100.88999938964844	0.8300018310546875	0.8295041488169634	yfinance
3629	2026-03-06	CM.IRON_ORE	101.91000366210938	1.0200042724609375	1.0110063223626031	yfinance
3630	2026-03-09	CM.IRON_ORE	102.9000015258789	0.9899978637695312	0.9714432618920777	yfinance
3631	2025-12-10	EQ.STOXX600	578.1699829101562	\N	\N	yfinance
3632	2025-12-11	EQ.STOXX600	581.3400268554688	3.1700439453125	0.5482892642327133	yfinance
3633	2025-12-12	EQ.STOXX600	578.239990234375	-3.10003662109375	-0.5332570402664658	yfinance
3634	2025-12-15	EQ.STOXX600	582.5399780273438	4.29998779296875	0.7436337620346629	yfinance
3635	2025-12-16	EQ.STOXX600	579.7999877929688	-2.739990234375	-0.4703523084636069	yfinance
3636	2025-12-17	EQ.STOXX600	579.7899780273438	-0.010009765625	-0.001726417012029021	yfinance
3637	2025-12-18	EQ.STOXX600	585.3499755859375	5.55999755859375	0.9589675174294807	yfinance
4849	2024-03-19	EQ.SHEL	2591.9536	\N	\N	yfinance_direct
3638	2025-12-19	EQ.STOXX600	587.5	2.1500244140625	0.36730580058713036	yfinance
3639	2025-12-22	EQ.STOXX600	586.75	-0.75	-0.1276595744680851	yfinance
3640	2025-12-23	EQ.STOXX600	588.72998046875	1.97998046875	0.3374487377503196	yfinance
3641	2025-12-29	EQ.STOXX600	589.25	0.52001953125	0.0883290385239015	yfinance
3642	2025-12-30	EQ.STOXX600	592.780029296875	3.530029296875	0.5990715819898176	yfinance
3643	2026-01-05	EQ.STOXX600	601.760009765625	8.97998046875	1.5148925444404038	yfinance
3644	2026-01-06	EQ.STOXX600	605.280029296875	3.52001953125	0.5849540471492923	yfinance
3645	2026-01-07	EQ.STOXX600	604.989990234375	-0.2900390625	-0.04791816158826925	yfinance
3646	2026-01-08	EQ.STOXX600	603.8300170898438	-1.15997314453125	-0.19173427052600867	yfinance
3647	2026-01-09	EQ.STOXX600	609.6699829101562	5.8399658203125	0.9671539431673488	yfinance
3648	2026-01-12	EQ.STOXX600	610.9500122070312	1.280029296875	0.20995445614117283	yfinance
3649	2026-01-13	EQ.STOXX600	610.4400024414062	-0.510009765625	-0.0834781496742444	yfinance
3650	2026-01-14	EQ.STOXX600	611.5599975585938	1.1199951171875	0.18347341470220965	yfinance
3651	2026-01-15	EQ.STOXX600	614.5700073242188	3.010009765625	0.49218552188521947	yfinance
3652	2026-01-16	EQ.STOXX600	614.3800048828125	-0.19000244140625	-0.030916321841591838	yfinance
3653	2026-01-19	EQ.STOXX600	607.0599975585938	-7.32000732421875	-1.1914462166806643	yfinance
3654	2026-01-20	EQ.STOXX600	602.7999877929688	-4.260009765625	-0.7017444375774112	yfinance
3655	2026-01-21	EQ.STOXX600	602.6699829101562	-0.1300048828125	-0.021566835674381283	yfinance
3656	2026-01-22	EQ.STOXX600	608.8599853515625	6.19000244140625	1.0270965232939155	yfinance
3657	2026-01-23	EQ.STOXX600	608.3400268554688	-0.51995849609375	-0.08539869733655106	yfinance
3658	2026-01-26	EQ.STOXX600	609.5700073242188	1.22998046875	0.20218634553899287	yfinance
3659	2026-01-27	EQ.STOXX600	613.1099853515625	3.53997802734375	0.5807336294124626	yfinance
3660	2026-01-28	EQ.STOXX600	608.510009765625	-4.5999755859375	-0.7502692332273523	yfinance
3661	2026-01-29	EQ.STOXX600	607.1400146484375	-1.3699951171875	-0.22513929026659235	yfinance
3662	2026-01-30	EQ.STOXX600	611	3.8599853515625	0.6357652696960868	yfinance
3663	2026-02-02	EQ.STOXX600	617.3099975585938	6.30999755859375	1.0327328246470948	yfinance
3664	2026-02-03	EQ.STOXX600	617.9299926757812	0.6199951171875	0.10043497102582587	yfinance
3665	2026-02-04	EQ.STOXX600	618.1199951171875	0.19000244140625	0.030748214791046967	yfinance
3666	2026-02-05	EQ.STOXX600	611.6500244140625	-6.469970703125	-1.0467175878849184	yfinance
3667	2026-02-06	EQ.STOXX600	617.1199951171875	5.469970703125	0.8942974715590054	yfinance
3668	2026-02-09	EQ.STOXX600	621.4099731445312	4.28997802734375	0.6951610807115572	yfinance
3669	2026-02-10	EQ.STOXX600	620.969970703125	-0.44000244140625	-0.0708071097056422	yfinance
3670	2026-02-11	EQ.STOXX600	621.5800170898438	0.61004638671875	0.09824088369812695	yfinance
3671	2026-02-12	EQ.STOXX600	618.52001953125	-3.05999755859375	-0.4922934255383978	yfinance
3672	2026-02-13	EQ.STOXX600	617.7000122070312	-0.82000732421875	-0.13257571272150553	yfinance
3673	2026-02-16	EQ.STOXX600	618.52001953125	0.82000732421875	0.13275170924618868	yfinance
3674	2026-02-17	EQ.STOXX600	621.2899780273438	2.76995849609375	0.4478365143610038	yfinance
3675	2026-02-18	EQ.STOXX600	628.6900024414062	7.4000244140625	1.191074164363362	yfinance
3676	2026-02-19	EQ.STOXX600	625.3300170898438	-3.3599853515625	-0.5344423067830874	yfinance
3677	2026-02-20	EQ.STOXX600	630.5599975585938	5.22998046875	0.8363552565554496	yfinance
3678	2026-02-23	EQ.STOXX600	627.7000122070312	-2.8599853515625	-0.45356276367606724	yfinance
3679	2026-02-24	EQ.STOXX600	629.1400146484375	1.44000244140625	0.22940933780503114	yfinance
3680	2026-02-25	EQ.STOXX600	633.469970703125	4.3299560546875	0.6882340900073052	yfinance
3681	2026-02-26	EQ.STOXX600	633.1799926757812	-0.28997802734375	-0.04577612842829576	yfinance
3682	2026-02-27	EQ.STOXX600	633.8499755859375	0.66998291015625	0.10581239424905733	yfinance
3683	2026-03-02	EQ.STOXX600	623.6300048828125	-10.219970703125	-1.6123642970369374	yfinance
3684	2026-03-03	EQ.STOXX600	604.4400024414062	-19.19000244140625	-3.077145469453844	yfinance
3685	2026-03-04	EQ.STOXX600	612.7100219726562	8.27001953125	1.368211815539407	yfinance
3686	2026-03-05	EQ.STOXX600	604.8300170898438	-7.8800048828125	-1.2860904180157453	yfinance
3687	2026-03-06	EQ.STOXX600	598.6900024414062	-6.1400146484375	-1.0151636782149718	yfinance
3688	2026-03-09	EQ.STOXX600	594.9199829101562	-3.77001953125	-0.6297114559916126	yfinance
3689	2025-12-10	EQ.DAX	24130.140625	\N	\N	yfinance
3690	2025-12-11	EQ.DAX	24294.609375	164.46875	0.6815905160105133	yfinance
3691	2025-12-12	EQ.DAX	24186.490234375	-108.119140625	-0.4450334597116773	yfinance
3692	2025-12-15	EQ.DAX	24229.91015625	43.419921875	0.17952138344276808	yfinance
3693	2025-12-16	EQ.DAX	24076.869140625	-153.041015625	-0.631620235643027	yfinance
3694	2025-12-17	EQ.DAX	23960.58984375	-116.279296875	-0.4829502382384156	yfinance
3695	2025-12-18	EQ.DAX	24199.5	238.91015625	0.9970963060924751	yfinance
3696	2025-12-19	EQ.DAX	24288.400390625	88.900390625	0.36736457623091384	yfinance
3697	2025-12-22	EQ.DAX	24283.970703125	-4.4296875	-0.01823787251839689	yfinance
3698	2025-12-23	EQ.DAX	24340.060546875	56.08984375	0.2309747628825052	yfinance
3699	2025-12-29	EQ.DAX	24351.119140625	11.05859375	0.04543371504233913	yfinance
3700	2025-12-30	EQ.DAX	24490.41015625	139.291015625	0.5720107351970556	yfinance
3701	2026-01-02	EQ.DAX	24539.33984375	48.9296875	0.19979121291895982	yfinance
3702	2026-01-05	EQ.DAX	24868.689453125	329.349609375	1.3421290526643204	yfinance
3703	2026-01-06	EQ.DAX	24892.19921875	23.509765625	0.09453560337111276	yfinance
3704	2026-01-07	EQ.DAX	25122.259765625	230.060546875	0.924227485298717	yfinance
3705	2026-01-08	EQ.DAX	25127.4609375	5.201171875	0.020703439593108608	yfinance
3706	2026-01-09	EQ.DAX	25261.640625	134.1796875	0.5339962037300451	yfinance
3707	2026-01-12	EQ.DAX	25405.33984375	143.69921875	0.5688435714970512	yfinance
3708	2026-01-13	EQ.DAX	25420.66015625	15.3203125	0.0603035133331191	yfinance
3709	2026-01-14	EQ.DAX	25286.240234375	-134.419921875	-0.5287821836599751	yfinance
3710	2026-01-15	EQ.DAX	25352.390625	66.150390625	0.26160627286563876	yfinance
3711	2026-01-16	EQ.DAX	25297.130859375	-55.259765625	-0.21796668583399126	yfinance
3712	2026-01-19	EQ.DAX	24959.060546875	-338.0703125	-1.3363978483540662	yfinance
3713	2026-01-20	EQ.DAX	24703.119140625	-255.94140625	-1.0254448710892892	yfinance
3714	2026-01-21	EQ.DAX	24560.98046875	-142.138671875	-0.5753875495068508	yfinance
3715	2026-01-22	EQ.DAX	24856.470703125	295.490234375	1.203088104528095	yfinance
3716	2026-01-23	EQ.DAX	24900.7109375	44.240234375	0.17798276715703665	yfinance
3717	2026-01-26	EQ.DAX	24933.080078125	32.369140625	0.12999283717740237	yfinance
3718	2026-01-27	EQ.DAX	24894.439453125	-38.640625	-0.1549773428670824	yfinance
3719	2026-01-28	EQ.DAX	24822.7890625	-71.650390625	-0.2878168466492855	yfinance
3720	2026-01-29	EQ.DAX	24309.4609375	-513.328125	-2.0679711844930804	yfinance
3721	2026-01-30	EQ.DAX	24538.810546875	229.349609375	0.9434582279083086	yfinance
3722	2026-02-02	EQ.DAX	24797.51953125	258.708984375	1.0542849413210307	yfinance
3723	2026-02-03	EQ.DAX	24780.7890625	-16.73046875	-0.06746831564712007	yfinance
3724	2026-02-04	EQ.DAX	24603.0390625	-177.75	-0.7172895082222526	yfinance
3725	2026-02-05	EQ.DAX	24491.060546875	-111.978515625	-0.45514099026765303	yfinance
3726	2026-02-06	EQ.DAX	24721.4609375	230.400390625	0.9407530155095654	yfinance
3727	2026-02-09	EQ.DAX	25014.869140625	293.408203125	1.186856245538179	yfinance
3728	2026-02-10	EQ.DAX	24987.849609375	-27.01953125	-0.10801388205593032	yfinance
3729	2026-02-11	EQ.DAX	24856.150390625	-131.69921875	-0.5270530310082736	yfinance
3730	2026-02-12	EQ.DAX	24852.689453125	-3.4609375	-0.013923867717284823	yfinance
3731	2026-02-13	EQ.DAX	24914.880859375	62.19140625	0.25024014550739093	yfinance
3732	2026-02-16	EQ.DAX	24800.91015625	-113.970703125	-0.457440289473088	yfinance
3733	2026-02-17	EQ.DAX	24998.400390625	197.490234375	0.796302366045349	yfinance
3734	2026-02-18	EQ.DAX	25278.2109375	279.810546875	1.1193138060943117	yfinance
3735	2026-02-19	EQ.DAX	25043.5703125	-234.640625	-0.9282327201879336	yfinance
3736	2026-02-20	EQ.DAX	25260.689453125	217.119140625	0.8669656040082644	yfinance
3737	2026-02-23	EQ.DAX	24991.970703125	-268.71875	-1.0637823266805444	yfinance
3738	2026-02-24	EQ.DAX	24986.25	-5.720703125	-0.022890164176947767	yfinance
3739	2026-02-25	EQ.DAX	25175.939453125	189.689453125	0.759175358947421	yfinance
3740	2026-02-26	EQ.DAX	25289.01953125	113.080078125	0.44915931870404846	yfinance
3741	2026-02-27	EQ.DAX	25284.259765625	-4.759765625	-0.018821471584211834	yfinance
3742	2026-03-02	EQ.DAX	24638	-646.259765625	-2.5559766100157577	yfinance
3743	2026-03-03	EQ.DAX	23790.650390625	-847.349609375	-3.43919802490056	yfinance
3744	2026-03-04	EQ.DAX	24205.359375	414.708984375	1.7431595083185334	yfinance
3745	2026-03-05	EQ.DAX	23815.75	-389.609375	-1.6095996302471753	yfinance
3746	2026-03-06	EQ.DAX	23591.029296875	-224.720703125	-0.9435802069008954	yfinance
3747	2026-03-09	EQ.DAX	23409.369140625	-181.66015625	-0.7700391278563827	yfinance
3748	2025-12-10	EQ.FTSE	9655.5	\N	\N	yfinance
3749	2025-12-11	EQ.FTSE	9703.2001953125	47.7001953125	0.494020975739216	yfinance
3750	2025-12-12	EQ.FTSE	9649	-54.2001953125	-0.5585806148643977	yfinance
3751	2025-12-15	EQ.FTSE	9751.2998046875	102.2998046875	1.060211469452793	yfinance
3752	2025-12-16	EQ.FTSE	9684.7998046875	-66.5	-0.6819603676633254	yfinance
3753	2025-12-17	EQ.FTSE	9774.2998046875	89.5	0.9241285499436083	yfinance
3754	2025-12-18	EQ.FTSE	9837.7998046875	63.5	0.6496629044419842	yfinance
3755	2025-12-19	EQ.FTSE	9897.400390625	59.6005859375	0.6058324739348894	yfinance
3756	2025-12-22	EQ.FTSE	9866	-31.400390625	-0.31725897089849	yfinance
3757	2025-12-23	EQ.FTSE	9889.2001953125	23.2001953125	0.23515300337016015	yfinance
3758	2025-12-24	EQ.FTSE	9870.7001953125	-18.5	-0.18707276255534835	yfinance
3759	2025-12-29	EQ.FTSE	9866.5	-4.2001953125	-0.04255215161427588	yfinance
3760	2025-12-30	EQ.FTSE	9940.7001953125	74.2001953125	0.7520417099528708	yfinance
3761	2025-12-31	EQ.FTSE	9931.400390625	-9.2998046875	-0.09355281323025201	yfinance
3762	2026-01-02	EQ.FTSE	9951.099609375	19.69921875	0.198352880512154	yfinance
3763	2026-01-05	EQ.FTSE	10004.599609375	53.5	0.5376290269428846	yfinance
3764	2026-01-06	EQ.FTSE	10122.7001953125	118.1005859375	1.180462892556256	yfinance
3765	2026-01-07	EQ.FTSE	10048.2001953125	-74.5	-0.7359696381653047	yfinance
3766	2026-01-08	EQ.FTSE	10044.7001953125	-3.5	-0.03483210855644332	yfinance
3767	2026-01-09	EQ.FTSE	10124.599609375	79.8994140625	0.7954385149273662	yfinance
3768	2026-01-12	EQ.FTSE	10140.7001953125	16.1005859375	0.1590244212975243	yfinance
3769	2026-01-13	EQ.FTSE	10137.400390625	-3.2998046875	-0.032540205547397234	yfinance
3770	2026-01-14	EQ.FTSE	10184.400390625	47	0.4636297096784821	yfinance
3771	2026-01-15	EQ.FTSE	10238.900390625	54.5	0.5351321423907159	yfinance
3772	2026-01-16	EQ.FTSE	10235.2998046875	-3.6005859375	-0.035165748275047086	yfinance
3773	2026-01-19	EQ.FTSE	10195.400390625	-39.8994140625	-0.38982164493342064	yfinance
3774	2026-01-20	EQ.FTSE	10126.7998046875	-68.6005859375	-0.6728581841727418	yfinance
3775	2026-01-21	EQ.FTSE	10138.099609375	11.2998046875	0.11158317440292972	yfinance
3776	2026-01-22	EQ.FTSE	10150.099609375	12	0.11836537874320396	yfinance
3777	2026-01-23	EQ.FTSE	10143.400390625	-6.69921875	-0.06600150745133929	yfinance
3778	2026-01-26	EQ.FTSE	10148.900390625	5.5	0.05422244797793208	yfinance
3779	2026-01-27	EQ.FTSE	10207.7998046875	58.8994140625	0.5803526667471095	yfinance
3780	2026-01-28	EQ.FTSE	10154.400390625	-53.3994140625	-0.5231236415704252	yfinance
3781	2026-01-29	EQ.FTSE	10171.7998046875	17.3994140625	0.17134851289263642	yfinance
3782	2026-01-30	EQ.FTSE	10223.5	51.7001953125	0.5082698864037302	yfinance
3783	2026-02-02	EQ.FTSE	10341.599609375	118.099609375	1.155177868391451	yfinance
3784	2026-02-03	EQ.FTSE	10314.599609375	-27	-0.2610814672763352	yfinance
3785	2026-02-04	EQ.FTSE	10402.2998046875	87.7001953125	0.8502530261357772	yfinance
3786	2026-02-05	EQ.FTSE	10309.2001953125	-93.099609375	-0.8949906378688232	yfinance
3787	2026-02-06	EQ.FTSE	10369.7998046875	60.599609375	0.5878206672381248	yfinance
3788	2026-02-09	EQ.FTSE	10386.2001953125	16.400390625	0.15815532540547667	yfinance
3789	2026-02-10	EQ.FTSE	10353.7998046875	-32.400390625	-0.31195615350860406	yfinance
3790	2026-02-11	EQ.FTSE	10472.099609375	118.2998046875	1.1425738078685068	yfinance
3791	2026-02-12	EQ.FTSE	10402.400390625	-69.69921875	-0.6655706243244932	yfinance
3792	2026-02-13	EQ.FTSE	10446.400390625	44	0.4229792965828763	yfinance
3793	2026-02-16	EQ.FTSE	10473.7001953125	27.2998046875	0.26133216865782677	yfinance
3794	2026-02-17	EQ.FTSE	10556.2001953125	82.5	0.7876872400541199	yfinance
3795	2026-02-18	EQ.FTSE	10686.2001953125	130	1.2315037380375444	yfinance
3796	2026-02-19	EQ.FTSE	10627	-59.2001953125	-0.5539873316098659	yfinance
3797	2026-02-20	EQ.FTSE	10686.900390625	59.900390625	0.5636622812176532	yfinance
3798	2026-02-23	EQ.FTSE	10684.7001953125	-2.2001953125	-0.020587777859613104	yfinance
3799	2026-02-24	EQ.FTSE	10680.599609375	-4.1005859375	-0.03837810947001558	yfinance
3800	2026-02-25	EQ.FTSE	10806.400390625	125.80078125	1.1778438088773326	yfinance
3801	2026-02-26	EQ.FTSE	10846.7001953125	40.2998046875	0.37292533342056944	yfinance
3802	2026-02-27	EQ.FTSE	10910.599609375	63.8994140625	0.589113858702527	yfinance
3803	2026-03-02	EQ.FTSE	10780.099609375	-130.5	-1.1960845844610324	yfinance
3804	2026-03-03	EQ.FTSE	10484.099609375	-296	-2.7458002312203242	yfinance
3805	2026-03-04	EQ.FTSE	10567.7001953125	83.6005859375	0.79740358306729	yfinance
3806	2026-03-05	EQ.FTSE	10413.900390625	-153.7998046875	-1.4553763055818025	yfinance
3807	2026-03-06	EQ.FTSE	10284.7998046875	-129.1005859375	-1.2396948414613356	yfinance
3808	2026-03-09	EQ.FTSE	10249.5	-35.2998046875	-0.3432230608067978	yfinance
3809	2025-12-10	EQ.NIKKEI	50602.80078125	\N	\N	yfinance
3810	2025-12-11	EQ.NIKKEI	50148.8203125	-453.98046875	-0.8971449440368026	yfinance
3811	2025-12-12	EQ.NIKKEI	50836.55078125	687.73046875	1.3713791560089352	yfinance
3812	2025-12-15	EQ.NIKKEI	50168.109375	-668.44140625	-1.314883476509466	yfinance
3813	2025-12-16	EQ.NIKKEI	49383.2890625	-784.8203125	-1.564380883149436	yfinance
3814	2025-12-17	EQ.NIKKEI	49512.28125	128.9921875	0.2612061487778713	yfinance
3815	2025-12-18	EQ.NIKKEI	49001.5	-510.78125	-1.0316253606270667	yfinance
3816	2025-12-19	EQ.NIKKEI	49507.2109375	505.7109375	1.0320315449527055	yfinance
3817	2025-12-22	EQ.NIKKEI	50402.390625	895.1796875	1.8081804055375141	yfinance
3818	2025-12-23	EQ.NIKKEI	50412.87109375	10.48046875	0.02079359454986169	yfinance
3819	2025-12-24	EQ.NIKKEI	50344.1015625	-68.76953125	-0.13641264573508052	yfinance
3820	2025-12-25	EQ.NIKKEI	50407.7890625	63.6875	0.12650439281538225	yfinance
3821	2025-12-26	EQ.NIKKEI	50750.390625	342.6015625	0.6796599669848891	yfinance
3822	2025-12-29	EQ.NIKKEI	50526.921875	-223.46875	-0.4403291230824886	yfinance
3823	2025-12-30	EQ.NIKKEI	50339.48046875	-187.44140625	-0.37097333321376014	yfinance
3824	2026-01-05	EQ.NIKKEI	51832.80078125	1493.3203125	2.966499253855095	yfinance
3825	2026-01-06	EQ.NIKKEI	52518.078125	685.27734375	1.3220920602806636	yfinance
3826	2026-01-07	EQ.NIKKEI	51961.98046875	-556.09765625	-1.0588690144494888	yfinance
3827	2026-01-08	EQ.NIKKEI	51117.26171875	-844.71875	-1.6256477185430123	yfinance
3828	2026-01-09	EQ.NIKKEI	51939.890625	822.62890625	1.6092976786905169	yfinance
3829	2026-01-13	EQ.NIKKEI	53549.16015625	1609.26953125	3.098330612339444	yfinance
3830	2026-01-14	EQ.NIKKEI	54341.23046875	792.0703125	1.479146097135481	yfinance
3831	2026-01-15	EQ.NIKKEI	54110.5	-230.73046875	-0.4245955911555704	yfinance
3832	2026-01-16	EQ.NIKKEI	53936.171875	-174.328125	-0.3221706045961505	yfinance
3833	2026-01-19	EQ.NIKKEI	53583.5703125	-352.6015625	-0.6537385769927707	yfinance
3834	2026-01-20	EQ.NIKKEI	52991.1015625	-592.46875	-1.1056910663935147	yfinance
3835	2026-01-21	EQ.NIKKEI	52774.640625	-216.4609375	-0.4084854458907532	yfinance
3836	2026-01-22	EQ.NIKKEI	53688.890625	914.25	1.7323661311052272	yfinance
3837	2026-01-23	EQ.NIKKEI	53846.87109375	157.98046875	0.2942516913851766	yfinance
3838	2026-01-26	EQ.NIKKEI	52885.25	-961.62109375	-1.7858439575361236	yfinance
3839	2026-01-27	EQ.NIKKEI	53333.5390625	448.2890625	0.8476636916720636	yfinance
3840	2026-01-28	EQ.NIKKEI	53358.7109375	25.171875	0.047197083565937416	yfinance
3841	2026-01-29	EQ.NIKKEI	53375.6015625	16.890625	0.031654859540711705	yfinance
3842	2026-01-30	EQ.NIKKEI	53322.8515625	-52.75	-0.09882792597331676	yfinance
3843	2026-02-02	EQ.NIKKEI	52655.1796875	-667.671875	-1.2521308509118614	yfinance
3844	2026-02-03	EQ.NIKKEI	54720.66015625	2065.48046875	3.9226539174460964	yfinance
3845	2026-02-04	EQ.NIKKEI	54293.359375	-427.30078125	-0.7808765099505022	yfinance
3846	2026-02-05	EQ.NIKKEI	53818.0390625	-475.3203125	-0.875466756840371	yfinance
3847	2026-02-06	EQ.NIKKEI	54253.6796875	435.640625	0.8094695246961369	yfinance
3848	2026-02-09	EQ.NIKKEI	56363.94140625	2110.26171875	3.8896195260949322	yfinance
3849	2026-02-10	EQ.NIKKEI	57650.5390625	1286.59765625	2.2826609072220307	yfinance
3850	2026-02-12	EQ.NIKKEI	57639.83984375	-10.69921875	-0.018558748840840467	yfinance
3851	2026-02-13	EQ.NIKKEI	56941.96875	-697.87109375	-1.2107443317708515	yfinance
3852	2026-02-16	EQ.NIKKEI	56806.41015625	-135.55859375	-0.2380644658514727	yfinance
3853	2026-02-17	EQ.NIKKEI	56566.48828125	-239.921875	-0.4223500030015594	yfinance
3854	2026-02-18	EQ.NIKKEI	57143.83984375	577.3515625	1.020660076385498	yfinance
3855	2026-02-19	EQ.NIKKEI	57467.828125	323.98828125	0.5669697418582479	yfinance
3856	2026-02-20	EQ.NIKKEI	56825.69921875	-642.12890625	-1.1173711051917363	yfinance
3857	2026-02-24	EQ.NIKKEI	57321.08984375	495.390625	0.8717721590947758	yfinance
3858	2026-02-25	EQ.NIKKEI	58583.12109375	1262.03125	2.2016874651897522	yfinance
3859	2026-02-26	EQ.NIKKEI	58753.390625	170.26953125	0.29064605652798753	yfinance
3860	2026-02-27	EQ.NIKKEI	58850.26953125	96.87890625	0.16489074965620334	yfinance
3861	2026-03-02	EQ.NIKKEI	58057.23828125	-793.03125	-1.3475405572762815	yfinance
3862	2026-03-03	EQ.NIKKEI	56279.05078125	-1778.1875	-3.062817923556447	yfinance
3863	2026-03-04	EQ.NIKKEI	54245.5390625	-2033.51171875	-3.613265843189181	yfinance
3864	2026-03-05	EQ.NIKKEI	55278.05859375	1032.51953125	1.9034183254412194	yfinance
3865	2026-03-06	EQ.NIKKEI	55620.83984375	342.78125	0.6201036337386069	yfinance
3866	2026-03-09	EQ.NIKKEI	52728.71875	-2892.12109375	-5.199707702858395	yfinance
3867	2026-03-09	EQ.IHYG	92.36000061035156	-0.15999603271484375	-0.1729312997406319	yfinance
3868	2026-03-09	CM.SILVER	84.03199768066406	0.21599578857421875	0.25770232855094394	yfinance
3869	2026-03-09	EQ.MOVE	79.73999786376953	-1.5200042724609375	-1.8705442191752424	yfinance
3870	2025-12-10	FX.USDCHF	0.805899977684021	\N	\N	yfinance
3871	2025-12-11	FX.USDCHF	0.7993800044059753	-0.006519973278045654	-0.8090300854434345	yfinance
3872	2025-12-12	FX.USDCHF	0.7947900295257568	-0.004589974880218506	-0.5741918555530229	yfinance
3873	2025-12-15	FX.USDCHF	0.7961400151252747	0.0013499855995178223	0.16985437025717912	yfinance
3874	2025-12-16	FX.USDCHF	0.7960100173950195	-0.00012999773025512695	-0.01632850099045348	yfinance
3875	2025-12-17	FX.USDCHF	0.795199990272522	-0.0008100271224975586	-0.10176092069147706	yfinance
3876	2025-12-18	FX.USDCHF	0.795199990272522	0	0	yfinance
3877	2025-12-19	FX.USDCHF	0.7940099835395813	-0.0011900067329406738	-0.14964873585232918	yfinance
3878	2025-12-22	FX.USDCHF	0.7958300113677979	0.0018200278282165527	0.2292197662431312	yfinance
3879	2025-12-23	FX.USDCHF	0.7914299964904785	-0.004400014877319336	-0.5528837583992345	yfinance
3880	2025-12-24	FX.USDCHF	0.7874500155448914	-0.003979980945587158	-0.5028847735410595	yfinance
3881	2025-12-26	FX.USDCHF	0.7880499958992004	0.000599980354309082	0.07619281763476936	yfinance
3882	2025-12-29	FX.USDCHF	0.7892400026321411	0.0011900067329406738	0.1510065020155	yfinance
3883	2025-12-30	FX.USDCHF	0.7886999845504761	-0.0005400180816650391	-0.06842254318889833	yfinance
3884	2025-12-31	FX.USDCHF	0.791700005531311	0.003000020980834961	0.38037543294042786	yfinance
3885	2026-01-02	FX.USDCHF	0.7920299768447876	0.0003299713134765625	0.04167883177607385	yfinance
3886	2026-01-05	FX.USDCHF	0.79339998960495	0.0013700127601623535	0.17297486209045745	yfinance
3887	2026-01-06	FX.USDCHF	0.7921000123023987	-0.0012999773025512695	-0.1638489185257684	yfinance
3888	2026-01-07	FX.USDCHF	0.7954999804496765	0.003399968147277832	0.42923470451605444	yfinance
3889	2026-01-08	FX.USDCHF	0.7976499795913696	0.0021499991416931152	0.2702701690171977	yfinance
3890	2026-01-09	FX.USDCHF	0.7990099787712097	0.0013599991798400879	0.17050074777621205	yfinance
3891	2026-01-12	FX.USDCHF	0.8015260100364685	0.002516031265258789	0.31489359734006966	yfinance
3892	2026-01-13	FX.USDCHF	0.7973600029945374	-0.004166007041931152	-0.5197594326030173	yfinance
3893	2026-01-14	FX.USDCHF	0.801010012626648	0.0036500096321105957	0.45776181629411394	yfinance
3894	2026-01-15	FX.USDCHF	0.7997199892997742	-0.0012900233268737793	-0.16104958821220894	yfinance
3895	2026-01-16	FX.USDCHF	0.8034200072288513	0.0037000179290771484	0.46266417978583263	yfinance
3896	2026-01-19	FX.USDCHF	0.7987200021743774	-0.004700005054473877	-0.5849997525808561	yfinance
3897	2026-01-20	FX.USDCHF	0.7978900074958801	-0.0008299946784973145	-0.10391559948890688	yfinance
3898	2026-01-21	FX.USDCHF	0.7894999980926514	-0.00839000940322876	-1.0515245615821402	yfinance
3899	2026-01-22	FX.USDCHF	0.7963899970054626	0.006889998912811279	0.8727041075942735	yfinance
3900	2026-01-23	FX.USDCHF	0.7889999747276306	-0.007390022277832031	-0.9279401179848498	yfinance
3901	2026-01-26	FX.USDCHF	0.7778699994087219	-0.011129975318908691	-1.4106433048684002	yfinance
3902	2026-01-27	FX.USDCHF	0.777239978313446	-0.0006300210952758789	-0.08099310884270809	yfinance
3903	2026-01-28	FX.USDCHF	0.7631999850273132	-0.014039993286132812	-1.8063910346709868	yfinance
3904	2026-01-29	FX.USDCHF	0.7657399773597717	0.002539992332458496	0.33280822619088435	yfinance
3905	2026-01-30	FX.USDCHF	0.7644100189208984	-0.001329958438873291	-0.17368277459652984	yfinance
3906	2026-02-02	FX.USDCHF	0.7735599875450134	0.00914996862411499	1.1969974748671934	yfinance
3907	2026-02-03	FX.USDCHF	0.779009997844696	0.005450010299682617	0.7045362205171556	yfinance
3908	2026-02-04	FX.USDCHF	0.7757599949836731	-0.0032500028610229492	-0.41719655331957267	yfinance
3909	2026-02-05	FX.USDCHF	0.7773100137710571	0.0015500187873840332	0.1998064862079741	yfinance
3910	2026-02-06	FX.USDCHF	0.7777000069618225	0.00038999319076538086	0.050172155749462204	yfinance
3911	2026-02-09	FX.USDCHF	0.7758299708366394	-0.0018700361251831055	-0.24045725966862516	yfinance
3912	2026-02-10	FX.USDCHF	0.7671200037002563	-0.008709967136383057	-1.122664432129427	yfinance
3913	2026-02-11	FX.USDCHF	0.7685700058937073	0.0014500021934509277	0.1890189522443349	yfinance
3914	2026-02-12	FX.USDCHF	0.7711399793624878	0.0025699734687805176	0.33438378404997804	yfinance
3915	2026-02-13	FX.USDCHF	0.7695500254631042	-0.001589953899383545	-0.2061822680621464	yfinance
3916	2026-02-16	FX.USDCHF	0.7682099938392639	-0.001340031623840332	-0.17413184062126696	yfinance
3917	2026-02-17	FX.USDCHF	0.769599974155426	0.0013899803161621094	0.18093754667463247	yfinance
3918	2026-02-18	FX.USDCHF	0.7702000141143799	0.0006000399589538574	0.07796777275263723	yfinance
3919	2026-02-19	FX.USDCHF	0.7721999883651733	0.001999974250793457	0.2596694643135189	yfinance
3920	2026-02-20	FX.USDCHF	0.7753400206565857	0.0031400322914123535	0.4066345944992986	yfinance
3921	2026-02-23	FX.USDCHF	0.7717000246047974	-0.00363999605178833	-0.46947093595218403	yfinance
3922	2026-02-24	FX.USDCHF	0.7742300033569336	0.0025299787521362305	0.3278448453376533	yfinance
3923	2026-02-25	FX.USDCHF	0.7737299799919128	-0.000500023365020752	-0.06458331023762101	yfinance
3924	2026-02-26	FX.USDCHF	0.7721400260925293	-0.001589953899383545	-0.20549208903604374	yfinance
3925	2026-02-27	FX.USDCHF	0.7732300162315369	0.0010899901390075684	0.1411648279035012	yfinance
3926	2026-03-02	FX.USDCHF	0.7695299983024597	-0.0037000179290771484	-0.4785145236743126	yfinance
3927	2026-03-03	FX.USDCHF	0.7787100076675415	0.009180009365081787	1.1929371675350378	yfinance
3928	2026-03-04	FX.USDCHF	0.7819200158119202	0.003210008144378662	0.41222125216979705	yfinance
3929	2026-03-05	FX.USDCHF	0.7791500091552734	-0.0027700066566467285	-0.3542570340484818	yfinance
3930	2026-03-06	FX.USDCHF	0.7806599736213684	0.0015099644660949707	0.1937963740425313	yfinance
3931	2026-03-09	FX.USDCHF	0.781220018863678	0.0005600452423095703	0.0717399714643498	yfinance
3932	2025-12-10	CM.WHEAT	531.25	\N	\N	yfinance
3933	2025-12-11	CM.WHEAT	534.5	3.25	0.611764705882353	yfinance
3934	2025-12-12	CM.WHEAT	534.5	0	0	yfinance
3935	2025-12-15	CM.WHEAT	520.75	-13.75	-2.5724976613657624	yfinance
3936	2025-12-16	CM.WHEAT	509.5	-11.25	-2.1603456553048486	yfinance
3937	2025-12-17	CM.WHEAT	506.25	-3.25	-0.6378802747791953	yfinance
3938	2025-12-18	CM.WHEAT	507.75	1.5	0.2962962962962963	yfinance
3939	2025-12-19	CM.WHEAT	509.75	2	0.39389463318562284	yfinance
3940	2025-12-22	CM.WHEAT	515.5	5.75	1.1280039234919077	yfinance
3941	2025-12-23	CM.WHEAT	517	1.5	0.2909796314258002	yfinance
3942	2025-12-24	CM.WHEAT	521.75	4.75	0.9187620889748549	yfinance
3943	2025-12-26	CM.WHEAT	519	-2.75	-0.5270723526593196	yfinance
3944	2025-12-29	CM.WHEAT	513	-6	-1.1560693641618498	yfinance
3945	2025-12-30	CM.WHEAT	510.75	-2.25	-0.43859649122807015	yfinance
3946	2025-12-31	CM.WHEAT	507	-3.75	-0.7342143906020558	yfinance
3947	2026-01-02	CM.WHEAT	506.5	-0.5	-0.09861932938856016	yfinance
3948	2026-01-05	CM.WHEAT	512.5	6	1.1846001974333662	yfinance
3949	2026-01-06	CM.WHEAT	510.5	-2	-0.3902439024390244	yfinance
3950	2026-01-07	CM.WHEAT	518	7.5	1.4691478942213516	yfinance
3951	2026-01-08	CM.WHEAT	518	0	0	yfinance
3952	2026-01-09	CM.WHEAT	517.25	-0.75	-0.14478764478764478	yfinance
3953	2026-01-12	CM.WHEAT	511.25	-6	-1.1599806669888835	yfinance
3954	2026-01-13	CM.WHEAT	510.5	-0.75	-0.1466992665036675	yfinance
3955	2026-01-14	CM.WHEAT	512.5	2	0.3917727717923604	yfinance
3956	2026-01-15	CM.WHEAT	510.5	-2	-0.3902439024390244	yfinance
3957	2026-01-16	CM.WHEAT	518	7.5	1.4691478942213516	yfinance
3958	2026-01-20	CM.WHEAT	510.25	-7.75	-1.4961389961389961	yfinance
3959	2026-01-21	CM.WHEAT	507.75	-2.5	-0.4899559039686428	yfinance
3960	2026-01-22	CM.WHEAT	515.5	7.75	1.5263417035942886	yfinance
3961	2026-01-23	CM.WHEAT	529.5	14	2.7158098933074686	yfinance
3962	2026-01-26	CM.WHEAT	522.5	-7	-1.3220018885741265	yfinance
3963	2026-01-27	CM.WHEAT	523.25	0.75	0.14354066985645933	yfinance
3964	2026-01-28	CM.WHEAT	536	12.75	2.436693741041567	yfinance
3965	2026-01-29	CM.WHEAT	541.5	5.5	1.0261194029850746	yfinance
3966	2026-01-30	CM.WHEAT	538	-3.5	-0.6463527239150508	yfinance
3967	2026-02-02	CM.WHEAT	527.75	-10.25	-1.9052044609665428	yfinance
3968	2026-02-03	CM.WHEAT	528.75	1	0.18948365703458075	yfinance
3969	2026-02-04	CM.WHEAT	526.75	-2	-0.37825059101654845	yfinance
3970	2026-02-05	CM.WHEAT	535.25	8.5	1.6136687233032747	yfinance
3971	2026-02-06	CM.WHEAT	529.75	-5.5	-1.027557216254087	yfinance
3972	2026-02-09	CM.WHEAT	528.75	-1	-0.18876828692779613	yfinance
3973	2026-02-10	CM.WHEAT	528.25	-0.5	-0.09456264775413711	yfinance
3974	2026-02-11	CM.WHEAT	537.25	9	1.7037387600567913	yfinance
3975	2026-02-12	CM.WHEAT	552.5	15.25	2.8385295486272684	yfinance
3976	2026-02-13	CM.WHEAT	548.75	-3.75	-0.6787330316742082	yfinance
3977	2026-02-17	CM.WHEAT	537.75	-11	-2.0045558086560367	yfinance
3978	2026-02-18	CM.WHEAT	547	9.25	1.720130172013017	yfinance
3979	2026-02-19	CM.WHEAT	559.5	12.5	2.2851919561243146	yfinance
3980	2026-02-20	CM.WHEAT	573.5	14	2.5022341376228776	yfinance
3981	2026-02-23	CM.WHEAT	569.5	-4	-0.6974716652136007	yfinance
3982	2026-02-24	CM.WHEAT	567.5	-2	-0.35118525021949076	yfinance
3983	2026-02-25	CM.WHEAT	565.75	-1.75	-0.30837004405286345	yfinance
3984	2026-02-26	CM.WHEAT	571.75	6	1.0605391073795847	yfinance
3985	2026-02-27	CM.WHEAT	591.25	19.5	3.410581547879318	yfinance
3986	2026-03-02	CM.WHEAT	574.5	-16.75	-2.8329809725158563	yfinance
3987	2026-03-03	CM.WHEAT	572.25	-2.25	-0.391644908616188	yfinance
3988	2026-03-04	CM.WHEAT	566.75	-5.5	-0.9611183923110529	yfinance
3989	2026-03-05	CM.WHEAT	582.75	16	2.8231142479047198	yfinance
3990	2026-03-06	CM.WHEAT	611.25	28.5	4.890604890604891	yfinance
3991	2026-03-09	CM.WHEAT	598	-13.25	-2.1676891615541924	yfinance
3992	2025-12-10	CREDIT.IG_HY_DIFF	2.13	\N	\N	computed
3993	2025-12-11	CREDIT.IG_HY_DIFF	2.0999999999999996	-0.03000000000000025	-1.4084507042253638	computed
3994	2025-12-12	CREDIT.IG_HY_DIFF	2.1100000000000003	0.010000000000000675	0.4761904761905084	computed
3995	2025-12-15	CREDIT.IG_HY_DIFF	2.1100000000000003	0	0	computed
3996	2025-12-16	CREDIT.IG_HY_DIFF	2.17	0.05999999999999961	2.843601895734578	computed
3997	2025-12-17	CREDIT.IG_HY_DIFF	2.18	0.010000000000000231	0.46082949308756826	computed
3998	2025-12-18	CREDIT.IG_HY_DIFF	2.14	-0.040000000000000036	-1.8348623853211024	computed
3999	2025-12-19	CREDIT.IG_HY_DIFF	2.0999999999999996	-0.04000000000000048	-1.8691588785046953	computed
4000	2025-12-22	CREDIT.IG_HY_DIFF	2.08	-0.019999999999999574	-0.9523809523809322	computed
4001	2025-12-23	CREDIT.IG_HY_DIFF	2.04	-0.040000000000000036	-1.9230769230769247	computed
4002	2025-12-24	CREDIT.IG_HY_DIFF	2.05	0.009999999999999787	0.4901960784313621	computed
4003	2025-12-26	CREDIT.IG_HY_DIFF	2.07	0.020000000000000018	0.975609756097562	computed
4004	2025-12-29	CREDIT.IG_HY_DIFF	2.08	0.010000000000000231	0.4830917874396247	computed
4005	2025-12-30	CREDIT.IG_HY_DIFF	2.05	-0.03000000000000025	-1.4423076923077043	computed
4006	2025-12-31	CREDIT.IG_HY_DIFF	2.02	-0.029999999999999805	-1.463414634146332	computed
4007	2026-01-02	CREDIT.IG_HY_DIFF	2.04	0.020000000000000018	0.990099009900991	computed
4008	2026-01-05	CREDIT.IG_HY_DIFF	2.02	-0.020000000000000018	-0.980392156862746	computed
4009	2026-01-06	CREDIT.IG_HY_DIFF	2	-0.020000000000000018	-0.990099009900991	computed
4010	2026-01-07	CREDIT.IG_HY_DIFF	2	0	0	computed
4011	2026-01-08	CREDIT.IG_HY_DIFF	1.9699999999999998	-0.03000000000000025	-1.5000000000000124	computed
4012	2026-01-09	CREDIT.IG_HY_DIFF	1.9600000000000002	-0.009999999999999565	-0.5076142131979475	computed
4013	2026-01-12	CREDIT.IG_HY_DIFF	1.9600000000000002	0	0	computed
4014	2026-01-13	CREDIT.IG_HY_DIFF	1.98	0.019999999999999796	1.0204081632652957	computed
4015	2026-01-14	CREDIT.IG_HY_DIFF	1.9899999999999998	0.009999999999999787	0.5050505050504943	computed
4016	2026-01-15	CREDIT.IG_HY_DIFF	1.95	-0.039999999999999813	-2.0100502512562723	computed
4017	2026-01-16	CREDIT.IG_HY_DIFF	1.9	-0.050000000000000044	-2.5641025641025665	computed
4018	2026-01-19	CREDIT.IG_HY_DIFF	1.9	0	0	computed
4019	2026-01-20	CREDIT.IG_HY_DIFF	1.98	0.08000000000000007	4.210526315789478	computed
4020	2026-01-21	CREDIT.IG_HY_DIFF	1.95	-0.030000000000000027	-1.5151515151515165	computed
4021	2026-01-22	CREDIT.IG_HY_DIFF	1.9100000000000001	-0.039999999999999813	-2.0512820512820418	computed
4022	2026-01-23	CREDIT.IG_HY_DIFF	1.9500000000000002	0.040000000000000036	2.094240837696337	computed
4023	2026-01-26	CREDIT.IG_HY_DIFF	1.95	-2.220446049250313e-16	-1.1386902816668271e-14	computed
4024	2026-01-27	CREDIT.IG_HY_DIFF	1.98	0.030000000000000027	1.5384615384615399	computed
4025	2026-01-28	CREDIT.IG_HY_DIFF	1.9900000000000002	0.010000000000000231	0.5050505050505167	computed
4026	2026-01-29	CREDIT.IG_HY_DIFF	2.0300000000000002	0.040000000000000036	2.010050251256283	computed
4027	2026-01-30	CREDIT.IG_HY_DIFF	2.0599999999999996	0.02999999999999936	1.4778325123152392	computed
4028	2026-01-31	CREDIT.IG_HY_DIFF	2.13	0.07000000000000028	3.398058252427199	computed
4029	2026-02-02	CREDIT.IG_HY_DIFF	2.0700000000000003	-0.05999999999999961	-2.816901408450686	computed
4030	2026-02-03	CREDIT.IG_HY_DIFF	2.1100000000000003	0.040000000000000036	1.9323671497584556	computed
4031	2026-02-04	CREDIT.IG_HY_DIFF	2.11	-4.440892098500626e-16	-2.1046881983415287e-14	computed
4032	2026-02-05	CREDIT.IG_HY_DIFF	2.21	0.10000000000000009	4.739336492891	computed
4033	2026-02-06	CREDIT.IG_HY_DIFF	2.1100000000000003	-0.09999999999999964	-4.524886877828038	computed
4034	2026-02-09	CREDIT.IG_HY_DIFF	2.08	-0.03000000000000025	-1.4218009478673101	computed
4035	2026-02-10	CREDIT.IG_HY_DIFF	2.09	0.009999999999999787	0.4807692307692205	computed
4036	2026-02-11	CREDIT.IG_HY_DIFF	2.07	-0.020000000000000018	-0.9569377990430631	computed
4037	2026-02-12	CREDIT.IG_HY_DIFF	2.1399999999999997	0.06999999999999984	3.381642512077287	computed
4038	2026-02-13	CREDIT.IG_HY_DIFF	2.16	0.020000000000000462	0.9345794392523582	computed
4039	2026-02-16	CREDIT.IG_HY_DIFF	2.15	-0.010000000000000231	-0.4629629629629736	computed
4040	2026-02-17	CREDIT.IG_HY_DIFF	2.1399999999999997	-0.010000000000000231	-0.4651162790697782	computed
4041	2026-02-18	CREDIT.IG_HY_DIFF	2.08	-0.05999999999999961	-2.8037383177569914	computed
4042	2026-02-19	CREDIT.IG_HY_DIFF	2.09	0.009999999999999787	0.4807692307692205	computed
4043	2026-02-20	CREDIT.IG_HY_DIFF	2.08	-0.009999999999999787	-0.47846889952152094	computed
4044	2026-02-23	CREDIT.IG_HY_DIFF	2.1500000000000004	0.07000000000000028	3.3653846153846287	computed
4045	2026-02-24	CREDIT.IG_HY_DIFF	2.16	0.009999999999999787	0.46511627906975744	computed
4046	2026-02-25	CREDIT.IG_HY_DIFF	2.1399999999999997	-0.020000000000000462	-0.9259259259259472	computed
4047	2026-02-26	CREDIT.IG_HY_DIFF	2.16	0.020000000000000462	0.9345794392523582	computed
4048	2026-02-27	CREDIT.IG_HY_DIFF	2.25	0.08999999999999986	4.16666666666666	computed
4049	2026-02-28	CREDIT.IG_HY_DIFF	2.2600000000000002	0.010000000000000231	0.4444444444444547	computed
4050	2026-03-02	CREDIT.IG_HY_DIFF	2.1799999999999997	-0.08000000000000052	-3.53982300884958	computed
4051	2026-03-03	CREDIT.IG_HY_DIFF	2.24	0.0600000000000005	2.7522935779816744	computed
4052	2026-03-04	CREDIT.IG_HY_DIFF	2.1500000000000004	-0.08999999999999986	-4.017857142857136	computed
4053	2026-03-05	CREDIT.IG_HY_DIFF	2.18	0.029999999999999805	1.395348837209293	computed
4054	2026-03-06	CREDIT.IG_HY_DIFF	2.29	0.10999999999999988	5.045871559633022	computed
4055	2026-03-09	CREDIT.IG_HY_DIFF	2.34	0.04999999999999982	2.18340611353711	computed
4056	2025-12-09	CM.COPPER_GOLD_RATIO	0.001245750761876631	\N	\N	computed
4057	2025-12-10	CM.COPPER_GOLD_RATIO	0.0012571489713749124	1.139820949828149e-05	0.9149670902958817	computed
4058	2025-12-11	CM.COPPER_GOLD_RATIO	0.0012663633288475947	9.214357472682325e-06	0.7329566887052996	computed
4059	2025-12-12	CM.COPPER_GOLD_RATIO	0.0012286923733308692	-3.7670955516725486e-05	-2.97473518528103	computed
4060	2025-12-15	CM.COPPER_GOLD_RATIO	0.0012395801381063663	1.088776477549706e-05	0.88612617867736	computed
4061	2025-12-16	CM.COPPER_GOLD_RATIO	0.0012282495479825233	-1.1330590123842955e-05	-0.9140667695072935	computed
4062	2025-12-17	CM.COPPER_GOLD_RATIO	0.0012336975545153802	5.448006532856849e-06	0.44355860271274583	computed
4063	2025-12-18	CM.COPPER_GOLD_RATIO	0.0012366631871915822	2.9656326762019652e-06	0.2403857140956145	computed
4064	2025-12-19	CM.COPPER_GOLD_RATIO	0.0012471912635478345	1.0528076356252367e-05	0.8513293243701314	computed
4065	2025-12-22	CM.COPPER_GOLD_RATIO	0.001223394654305869	-2.3796609241965444e-05	-1.9080160306986227	computed
4066	2025-12-23	CM.COPPER_GOLD_RATIO	0.0012215579706297095	-1.8366836761595905e-06	-0.150130104761792	computed
4067	2025-12-24	CM.COPPER_GOLD_RATIO	0.0012271793399229033	5.621369293193823e-06	0.4601803130387605	computed
4068	2025-12-26	CM.COPPER_GOLD_RATIO	0.001273210984930404	4.603164500750073e-05	3.7510120574872685	computed
4069	2025-12-29	CM.COPPER_GOLD_RATIO	0.001269450382494591	-3.7606024358130454e-06	-0.2953636498838841	computed
4070	2025-12-30	CM.COPPER_GOLD_RATIO	0.001310610703156381	4.116032066179003e-05	3.242373331748971	computed
4071	2025-12-31	CM.COPPER_GOLD_RATIO	0.001301553538777529	-9.057164378851925e-06	-0.6910644295090251	computed
4072	2026-01-02	CM.COPPER_GOLD_RATIO	0.0013072501377124842	5.696598934955147e-06	0.4376768811450882	computed
4073	2026-01-05	CM.COPPER_GOLD_RATIO	0.0013352791631441466	2.8029025431662363e-05	2.14412105404016	computed
4074	2026-01-06	CM.COPPER_GOLD_RATIO	0.0013409708831188384	5.691719974691787e-06	0.42625693052003033	computed
4075	2026-01-07	CM.COPPER_GOLD_RATIO	0.0013055986942347188	-3.5372188884119594e-05	-2.637804394518306	computed
4076	2026-01-08	CM.COPPER_GOLD_RATIO	0.0012914353244095843	-1.4163369825134471e-05	-1.0848180139638064	computed
4077	2026-01-09	CM.COPPER_GOLD_RATIO	0.0013040332440920283	1.2597919682443958e-05	0.9754975293248647	computed
4078	2026-01-12	CM.COPPER_GOLD_RATIO	0.0012998719430522866	-4.1613010397416675e-06	-0.31911004252342945	computed
4079	2026-01-13	CM.COPPER_GOLD_RATIO	0.0013008802266437464	1.008283591459819e-06	0.07756791712052458	computed
4080	2026-01-14	CM.COPPER_GOLD_RATIO	0.0012988781700735076	-2.002056570238808e-06	-0.15390014616518677	computed
4081	2026-01-15	CM.COPPER_GOLD_RATIO	0.0012884778298376317	-1.0400340235875967e-05	-0.8007171477281361	computed
4082	2026-01-16	CM.COPPER_GOLD_RATIO	0.0012615508576740576	-2.6926972163574068e-05	-2.0898281320810397	computed
4083	2026-01-20	CM.COPPER_GOLD_RATIO	0.001212916977275369	-4.86338803986886e-05	-3.8550867848764936	computed
4084	2026-01-21	CM.COPPER_GOLD_RATIO	0.0011857899847870644	-2.7126992488304578e-05	-2.2365085984072164	computed
4085	2026-01-22	CM.COPPER_GOLD_RATIO	0.001169837853818159	-1.5952130968905492e-05	-1.3452745573466873	computed
4086	2026-01-23	CM.COPPER_GOLD_RATIO	0.001187854094073813	1.801624025565417e-05	1.5400630264144732	computed
4087	2026-01-26	CM.COPPER_GOLD_RATIO	0.001178022319410825	-9.83177466298813e-06	-0.8276921140431881	computed
4088	2026-01-27	CM.COPPER_GOLD_RATIO	0.0011473650871185888	-3.0657232292236134e-05	-2.602432210925254	computed
4089	2026-01-28	CM.COPPER_GOLD_RATIO	0.0011114568838021246	-3.590820331646422e-05	-3.129623144333382	computed
4090	2026-01-29	CM.COPPER_GOLD_RATIO	0.0011611574965160476	4.970061271392296e-05	4.471663583017693	computed
4091	2026-01-30	CM.COPPER_GOLD_RATIO	0.0012509811319998609	8.98236354838133e-05	7.735697849199719	computed
4092	2026-02-02	CM.COPPER_GOLD_RATIO	0.0012550567536176122	4.075621617751282e-06	0.3257940118757796	computed
4093	2026-02-03	CM.COPPER_GOLD_RATIO	0.0012363113074888243	-1.8745446128787908e-05	-1.4935935028241198	computed
4094	2026-02-04	CM.COPPER_GOLD_RATIO	0.0011840501441453832	-5.226116334344105e-05	-4.227184773517367	computed
4095	2026-02-05	CM.COPPER_GOLD_RATIO	0.0011928662325395556	8.81608839417244e-06	0.7445705266592162	computed
4096	2026-02-06	CM.COPPER_GOLD_RATIO	0.0011842583387775	-8.60789376205557e-06	-0.7216143375715967	computed
4097	2026-02-09	CM.COPPER_GOLD_RATIO	0.0011770180139390094	-7.240324838490679e-06	-0.6113805241147685	computed
4098	2026-02-10	CM.COPPER_GOLD_RATIO	0.001178304516284597	1.2865023455875188e-06	0.10930183993378417	computed
4099	2026-02-11	CM.COPPER_GOLD_RATIO	0.0011730025568249378	-5.301959459659165e-06	-0.4499651309474051	computed
4100	2026-02-12	CM.COPPER_GOLD_RATIO	0.001172085967773062	-9.165890518757474e-07	-0.0781404138075148	computed
4101	2026-02-13	CM.COPPER_GOLD_RATIO	0.0011534249341046369	-1.8661033668425147e-05	-1.592121583357975	computed
4102	2026-02-17	CM.COPPER_GOLD_RATIO	0.0011536177291488982	1.927950442613159e-07	0.016715005767675706	computed
4103	2026-02-18	CM.COPPER_GOLD_RATIO	0.0011618369490813674	8.21921993246922e-06	0.7124734411400713	computed
4104	2026-02-19	CM.COPPER_GOLD_RATIO	0.001151550499714542	-1.028644936682541e-05	-0.8853608395703594	computed
4105	2026-02-20	CM.COPPER_GOLD_RATIO	0.0011525309976341623	9.80497919620283e-07	0.08514588981232141	computed
4106	2026-02-23	CM.COPPER_GOLD_RATIO	0.0011091896837185926	-4.334131391556966e-05	-3.760533469775462	computed
4107	2026-02-24	CM.COPPER_GOLD_RATIO	0.0011488033056425476	3.961362192395502e-05	3.571401943727892	computed
4108	2026-02-25	CM.COPPER_GOLD_RATIO	0.0011484903059795228	-3.1299966302480997e-07	-0.0272457139953719	computed
4109	2026-02-26	CM.COPPER_GOLD_RATIO	0.0011488457503531114	3.554443735885506e-07	0.03094883533085735	computed
4110	2026-02-27	CM.COPPER_GOLD_RATIO	0.0011479781879862275	-8.67562366883845e-07	-0.07551600087454258	computed
4111	2026-03-02	CM.COPPER_GOLD_RATIO	0.001113346155838767	-3.463203214746041e-05	-3.0167848579258805	computed
4112	2026-03-03	CM.COPPER_GOLD_RATIO	0.0011304186231859985	1.7072467347231364e-05	1.5334374900113135	computed
4113	2026-03-04	CM.COPPER_GOLD_RATIO	0.001143509979245282	1.3091356059283634e-05	1.1580980524176665	computed
4114	2026-03-05	CM.COPPER_GOLD_RATIO	0.001135766885355601	-7.743093889681129e-06	-0.6771339148952227	computed
4115	2026-03-06	CM.COPPER_GOLD_RATIO	0.0011187112299087228	-1.7055655446878175e-05	-1.501686276188463	computed
4116	2026-03-09	CM.COPPER_GOLD_RATIO	0.001139251677516775	2.0540447608052284e-05	1.8360812923750025	computed
4117	2025-12-09	RATES.REAL_TERM_PREM	0	\N	\N	computed
4118	2025-12-10	RATES.REAL_TERM_PREM	0	0	\N	computed
4119	2025-12-11	RATES.REAL_TERM_PREM	0	0	\N	computed
4120	2025-12-12	RATES.REAL_TERM_PREM	8.881784197001252e-16	8.881784197001252e-16	\N	computed
4121	2025-12-15	RATES.REAL_TERM_PREM	0	-8.881784197001252e-16	-100	computed
4122	2025-12-16	RATES.REAL_TERM_PREM	4.440892098500626e-16	4.440892098500626e-16	\N	computed
4123	2025-12-17	RATES.REAL_TERM_PREM	0	-4.440892098500626e-16	-100	computed
4124	2025-12-18	RATES.REAL_TERM_PREM	0	0	\N	computed
4125	2025-12-19	RATES.REAL_TERM_PREM	0	0	\N	computed
4126	2025-12-22	RATES.REAL_TERM_PREM	0	0	\N	computed
4127	2025-12-23	RATES.REAL_TERM_PREM	-4.440892098500626e-16	-4.440892098500626e-16	\N	computed
4128	2025-12-24	RATES.REAL_TERM_PREM	0	4.440892098500626e-16	-100	computed
4129	2025-12-26	RATES.REAL_TERM_PREM	-4.440892098500626e-16	-4.440892098500626e-16	\N	computed
4130	2025-12-29	RATES.REAL_TERM_PREM	0	4.440892098500626e-16	-100	computed
4131	2025-12-30	RATES.REAL_TERM_PREM	-4.440892098500626e-16	-4.440892098500626e-16	\N	computed
4132	2025-12-31	RATES.REAL_TERM_PREM	0	4.440892098500626e-16	-100	computed
4133	2026-01-02	RATES.REAL_TERM_PREM	4.440892098500626e-16	4.440892098500626e-16	\N	computed
4134	2026-01-05	RATES.REAL_TERM_PREM	0	-4.440892098500626e-16	-100	computed
4135	2026-01-06	RATES.REAL_TERM_PREM	-4.440892098500626e-16	-4.440892098500626e-16	\N	computed
4136	2026-01-07	RATES.REAL_TERM_PREM	4.440892098500626e-16	8.881784197001252e-16	-200	computed
4137	2026-01-08	RATES.REAL_TERM_PREM	4.440892098500626e-16	0	0	computed
4138	2026-01-09	RATES.REAL_TERM_PREM	0	-4.440892098500626e-16	-100	computed
4139	2026-01-12	RATES.REAL_TERM_PREM	4.440892098500626e-16	4.440892098500626e-16	\N	computed
4140	2026-01-13	RATES.REAL_TERM_PREM	0	-4.440892098500626e-16	-100	computed
4141	2026-01-14	RATES.REAL_TERM_PREM	0	0	\N	computed
4142	2026-01-15	RATES.REAL_TERM_PREM	0	0	\N	computed
4143	2026-01-16	RATES.REAL_TERM_PREM	0	0	\N	computed
4144	2026-01-20	RATES.REAL_TERM_PREM	0	0	\N	computed
4145	2026-01-21	RATES.REAL_TERM_PREM	0	0	\N	computed
4146	2026-01-22	RATES.REAL_TERM_PREM	-4.440892098500626e-16	-4.440892098500626e-16	\N	computed
4147	2026-01-23	RATES.REAL_TERM_PREM	4.440892098500626e-16	8.881784197001252e-16	-200	computed
4148	2026-01-26	RATES.REAL_TERM_PREM	0	-4.440892098500626e-16	-100	computed
4149	2026-01-27	RATES.REAL_TERM_PREM	4.440892098500626e-16	4.440892098500626e-16	\N	computed
4150	2026-01-28	RATES.REAL_TERM_PREM	0	-4.440892098500626e-16	-100	computed
4151	2026-01-29	RATES.REAL_TERM_PREM	4.440892098500626e-16	4.440892098500626e-16	\N	computed
4152	2026-01-30	RATES.REAL_TERM_PREM	0	-4.440892098500626e-16	-100	computed
4153	2026-02-02	RATES.REAL_TERM_PREM	0	0	\N	computed
4154	2026-02-03	RATES.REAL_TERM_PREM	4.440892098500626e-16	4.440892098500626e-16	\N	computed
4155	2026-02-04	RATES.REAL_TERM_PREM	0	-4.440892098500626e-16	-100	computed
4156	2026-02-05	RATES.REAL_TERM_PREM	4.440892098500626e-16	4.440892098500626e-16	\N	computed
4157	2026-02-06	RATES.REAL_TERM_PREM	0	-4.440892098500626e-16	-100	computed
4158	2026-02-09	RATES.REAL_TERM_PREM	-4.440892098500626e-16	-4.440892098500626e-16	\N	computed
4159	2026-02-10	RATES.REAL_TERM_PREM	4.440892098500626e-16	8.881784197001252e-16	-200	computed
4160	2026-02-11	RATES.REAL_TERM_PREM	-4.440892098500626e-16	-8.881784197001252e-16	-200	computed
4161	2026-02-12	RATES.REAL_TERM_PREM	0	4.440892098500626e-16	-100	computed
4162	2026-02-13	RATES.REAL_TERM_PREM	0	0	\N	computed
4163	2026-02-17	RATES.REAL_TERM_PREM	0	0	\N	computed
4164	2026-02-18	RATES.REAL_TERM_PREM	0	0	\N	computed
4165	2026-02-19	RATES.REAL_TERM_PREM	0	0	\N	computed
4166	2026-02-20	RATES.REAL_TERM_PREM	4.440892098500626e-16	4.440892098500626e-16	\N	computed
4167	2026-02-23	RATES.REAL_TERM_PREM	4.440892098500626e-16	0	0	computed
4168	2026-02-24	RATES.REAL_TERM_PREM	0	-4.440892098500626e-16	-100	computed
4169	2026-02-25	RATES.REAL_TERM_PREM	0	0	\N	computed
4170	2026-02-26	RATES.REAL_TERM_PREM	-4.440892098500626e-16	-4.440892098500626e-16	\N	computed
4171	2026-02-27	RATES.REAL_TERM_PREM	0	4.440892098500626e-16	-100	computed
4172	2026-03-02	RATES.REAL_TERM_PREM	0	0	\N	computed
4173	2026-03-03	RATES.REAL_TERM_PREM	-4.440892098500626e-16	-4.440892098500626e-16	\N	computed
4174	2026-03-04	RATES.REAL_TERM_PREM	0	4.440892098500626e-16	-100	computed
4175	2026-03-05	RATES.REAL_TERM_PREM	-4.440892098500626e-16	-4.440892098500626e-16	\N	computed
4176	2026-03-06	RATES.REAL_TERM_PREM	4.440892098500626e-16	8.881784197001252e-16	-200	computed
4177	2026-03-09	RATES.US3M	3.71	0.020000000000000018	0.542005420054201	fred
4178	2026-03-09	RATES.US2Y	3.56	0	0	fred
4179	2026-03-09	RATES.US5Y	3.71	-0.010000000000000231	-0.26881720430108147	fred
4180	2026-03-09	RATES.US10Y	4.12	-0.03000000000000025	-0.7228915662650661	fred
4181	2026-03-09	RATES.US30Y	4.72	-0.04999999999999982	-1.048218029350101	fred
4182	2026-03-10	RATES.2S10S	0.58	0.019999999999999907	3.5714285714285543	fred
4183	2026-03-09	RATES.REAL10Y	1.78	-0.020000000000000018	-1.111111111111112	fred
4184	2026-03-09	RATES.REAL5Y	1.15	-0.010000000000000009	-0.8620689655172422	fred
4185	2026-03-10	RATES.BREAKEVEN	2.33	-0.009999999999999787	-0.4273504273504183	fred
4186	2026-03-10	RATES.BREAKEVEN5Y	2.53	-0.03000000000000025	-1.1718750000000098	fred
4187	2026-03-10	CM.WTI	83.44999694824219	-11.319999694824219	-11.944708342091532	yfinance
4188	2026-03-10	CM.BRENT	87.80000305175781	-11.159996032714844	-11.277279846363605	yfinance
4189	2026-03-10	CM.GOLD	5229.7001953125	138.2001953125	2.714331637287636	yfinance
4190	2026-03-10	CM.COPPER	5.9039998054504395	0.1034998893737793	1.784327055792538	yfinance
4191	2026-03-10	CM.NATGAS	3.0199999809265137	-0.09999990463256836	-3.205125266043049	yfinance
4192	2026-03-10	FX.EURUSD	1.1617234945297241	0.009397506713867188	0.8155250175064975	yfinance
4193	2026-03-10	FX.GBPUSD	1.3424980640411377	0.012392520904541016	0.9316945537507885	yfinance
4194	2026-03-10	FX.USDJPY	157.84800720214844	-0.5789947509765625	-0.36546468962902806	yfinance
4195	2026-03-10	FX.DXY	98.83000183105469	-0.34999847412109375	-0.35289218899390223	yfinance
4196	2026-03-10	EQ.XLE	55.599998474121094	-0.720001220703125	-1.2784112652779236	yfinance
4197	2026-03-10	EQ.XLF	50.060001373291016	-0.2700004577636719	-0.5364602581776101	yfinance
4198	2026-03-10	EQ.XLU	46.560001373291016	-0.2899971008300781	-0.6189906302564047	yfinance
4199	2026-03-10	EQ.EEM	58.68000030517578	0.22999954223632812	0.3934979285443579	yfinance
4200	2026-03-10	EQ.GLD	477.8599853515625	5.329986572265625	1.1279678721001343	yfinance
4201	2026-03-10	EQ.SLV	80.08999633789062	1.8299942016601562	2.338351842202366	yfinance
4202	2026-03-10	EQ.XLK	139.75999450683594	0	0	yfinance
4203	2026-03-10	EQ.XLV	153.14999389648438	-1.1100006103515625	-0.7195647931274712	yfinance
4204	2026-03-10	EQ.XLY	114.44000244140625	-0.149993896484375	-0.13089615261186427	yfinance
4205	2026-03-10	EQ.XLP	85.72000122070312	-0.25	-0.2907991118415798	yfinance
4206	2026-03-10	EQ.XLI	170.02000427246094	-0.9199981689453125	-0.5381994593457805	yfinance
4207	2026-03-10	EQ.XLB	49.880001068115234	-0.1100006103515625	-0.2200452223608252	yfinance
4208	2026-03-10	FX.AUDUSD	0.7068586349487305	0.010238707065582275	1.4697694762616276	yfinance
4209	2026-03-10	FX.EURGBP	0.8653200268745422	-0.0009299516677856445	-0.10735373054213634	yfinance
4210	2026-03-10	EQ.SPX	6781.47998046875	-14.51025390625	-0.21351198877325123	yfinance
4211	2026-03-10	EQ.SX7E	5837.169921875	151.9697265625	2.6730760807297593	yfinance
4212	2026-03-10	EQ.VIX	24.93000030517578	-0.5699996948242188	-2.235292920879289	yfinance
4213	2026-03-10	EQ.SPY	677.1799926757812	-1.09002685546875	-0.16070691967515588	yfinance
4214	2026-03-10	EQ.LQD	110.05999755859375	-0.7600021362304688	-0.6857987171299047	yfinance
4215	2026-03-10	EQ.HYG	80.04000091552734	-0.12999725341796875	-0.16215199748916115	yfinance
4216	2026-03-10	EQ.IWM	253.36000061035156	-0.2599945068359375	-0.10251341055179998	yfinance
4217	2026-03-10	CM.IRON_ORE	103.22000122070312	0.31999969482421875	0.31098123428476354	yfinance
4218	2026-03-10	EQ.STOXX600	606.1199951171875	11.20001220703125	1.8826081706390851	yfinance
4219	2026-03-10	EQ.DAX	23968.630859375	559.26171875	2.3890507915458863	yfinance
4220	2026-03-10	EQ.FTSE	10412.2001953125	162.7001953125	1.5873964126298843	yfinance
4221	2026-03-10	EQ.NIKKEI	54248.390625	1519.671875	2.8820572754766585	yfinance
4222	2026-03-10	CM.SILVER	89.08300018310547	5.051002502441406	6.010808551328362	yfinance
4223	2026-03-10	EQ.MOVE	76.33000183105469	-3.4099960327148438	-4.276393433745251	yfinance
4224	2026-03-10	FX.USDCHF	0.7778800129890442	-0.003340005874633789	-0.42753715905693096	yfinance
4225	2026-03-10	CM.WHEAT	584.75	-13.25	-2.2157190635451505	yfinance
4226	2025-12-10	RATES.5S30S	1.06	\N	\N	computed
4227	2025-12-11	RATES.5S30S	1.0699999999999998	0.009999999999999787	0.9433962264150741	computed
4228	2025-12-12	RATES.5S30S	1.0999999999999996	0.029999999999999805	2.8037383177569914	computed
4229	2025-12-15	RATES.5S30S	1.1099999999999999	0.010000000000000231	0.9090909090909304	computed
4230	2025-12-16	RATES.5S30S	1.1300000000000003	0.020000000000000462	1.8018018018018436	computed
4231	2025-12-17	RATES.5S30S	1.13	-4.440892098500626e-16	-3.929993007522677e-14	computed
4232	2025-12-18	RATES.5S30S	1.1399999999999997	0.009999999999999787	0.8849557522123705	computed
4233	2025-12-19	RATES.5S30S	1.12	-0.019999999999999574	-1.7543859649122437	computed
4234	2025-12-22	RATES.5S30S	1.13	0.009999999999999787	0.8928571428571237	computed
4235	2025-12-23	RATES.5S30S	1.1099999999999999	-0.020000000000000018	-1.7699115044247804	computed
4236	2025-12-24	RATES.5S30S	1.0899999999999999	-0.020000000000000018	-1.8018018018018036	computed
4237	2025-12-26	RATES.5S30S	1.1299999999999994	0.03999999999999959	3.6697247706421647	computed
4238	2025-12-29	RATES.5S30S	1.13	4.440892098500626e-16	3.92999300752268e-14	computed
4239	2025-12-30	RATES.5S30S	1.1299999999999994	-4.440892098500626e-16	-3.9299930075226786e-14	computed
4240	2025-12-31	RATES.5S30S	1.1099999999999999	-0.019999999999999574	-1.769911504424742	computed
4241	2026-01-02	RATES.5S30S	1.12	0.010000000000000231	0.9009009009009218	computed
4242	2026-01-05	RATES.5S30S	1.1399999999999997	0.019999999999999574	1.7857142857142474	computed
4243	2026-01-06	RATES.5S30S	1.1400000000000001	4.440892098500626e-16	3.895519384649673e-14	computed
4244	2026-01-07	RATES.5S30S	1.12	-0.020000000000000018	-1.7543859649122822	computed
4245	2026-01-08	RATES.5S30S	1.1099999999999994	-0.010000000000000675	-0.8928571428572031	computed
4246	2026-01-09	RATES.5S30S	1.0700000000000003	-0.03999999999999915	-3.6036036036035286	computed
4247	2026-01-12	RATES.5S30S	1.06	-0.010000000000000231	-0.9345794392523578	computed
4248	2026-01-13	RATES.5S30S	1.08	0.020000000000000018	1.8867924528301903	computed
4249	2026-01-14	RATES.5S30S	1.0699999999999998	-0.010000000000000231	-0.9259259259259472	computed
4250	2026-01-15	RATES.5S30S	1.02	-0.04999999999999982	-4.672897196261666	computed
4251	2026-01-16	RATES.5S30S	1.0100000000000002	-0.009999999999999787	-0.9803921568627242	computed
4252	2026-01-20	RATES.5S30S	1.0500000000000003	0.040000000000000036	3.960396039603963	computed
4253	2026-01-21	RATES.5S30S	1.04	-0.010000000000000231	-0.9523809523809741	computed
4254	2026-01-22	RATES.5S30S	0.9899999999999998	-0.050000000000000266	-4.807692307692333	computed
4255	2026-01-23	RATES.5S30S	0.9800000000000004	-0.009999999999999343	-1.010101010100944	computed
4256	2026-01-26	RATES.5S30S	0.98	-4.440892098500626e-16	-4.531522549490433e-14	computed
4257	2026-01-27	RATES.5S30S	1.02	0.040000000000000036	4.081632653061228	computed
4258	2026-01-28	RATES.5S30S	1.0199999999999996	-4.440892098500626e-16	-4.353815782843751e-14	computed
4259	2026-01-29	RATES.5S30S	1.0499999999999998	0.03000000000000025	2.941176470588261	computed
4260	2026-01-30	RATES.5S30S	1.08	0.03000000000000025	2.857142857142881	computed
4261	2026-02-02	RATES.5S30S	1.0700000000000003	-0.009999999999999787	-0.9259259259259062	computed
4262	2026-02-03	RATES.5S30S	1.0700000000000003	0	0	computed
4263	2026-02-04	RATES.5S30S	1.08	0.009999999999999787	0.9345794392523162	computed
4264	2026-02-05	RATES.5S30S	1.1099999999999994	0.02999999999999936	2.777777777777718	computed
4265	2026-02-06	RATES.5S30S	1.0899999999999999	-0.019999999999999574	-1.8018018018017643	computed
4266	2026-02-09	RATES.5S30S	1.0999999999999996	0.009999999999999787	0.917431192660531	computed
4267	2026-02-10	RATES.5S30S	1.08	-0.019999999999999574	-1.81818181818178	computed
4268	2026-02-11	RATES.5S30S	1.0700000000000003	-0.009999999999999787	-0.9259259259259062	computed
4269	2026-02-12	RATES.5S30S	1.0499999999999998	-0.020000000000000462	-1.8691588785047155	computed
4270	2026-02-13	RATES.5S30S	1.0800000000000005	0.030000000000000693	2.857142857142924	computed
4271	2026-02-17	RATES.5S30S	1.0499999999999998	-0.030000000000000693	-2.7777777777778407	computed
4272	2026-02-18	RATES.5S30S	1.0499999999999998	0	0	computed
4273	2026-02-19	RATES.5S30S	1.0500000000000003	4.440892098500626e-16	4.229421046191073e-14	computed
4274	2026-02-20	RATES.5S30S	1.0699999999999998	0.019999999999999574	1.9047619047618636	computed
4275	2026-02-23	RATES.5S30S	1.1100000000000003	0.04000000000000048	3.738317757009391	computed
4276	2026-02-24	RATES.5S30S	1.0900000000000003	-0.020000000000000018	-1.801801801801803	computed
4277	2026-02-25	RATES.5S30S	1.0900000000000003	0	0	computed
4278	2026-02-26	RATES.5S30S	1.1	0.009999999999999787	0.9174311926605306	computed
4279	2026-02-27	RATES.5S30S	1.13	0.029999999999999805	2.7272727272727093	computed
4280	2026-03-02	RATES.5S30S	1.08	-0.04999999999999982	-4.424778761061932	computed
4281	2026-03-03	RATES.5S30S	1.0700000000000003	-0.009999999999999787	-0.9259259259259062	computed
4282	2026-03-04	RATES.5S30S	1.0499999999999998	-0.020000000000000462	-1.8691588785047155	computed
4283	2026-03-05	RATES.5S30S	1.02	-0.029999999999999805	-2.857142857142839	computed
4284	2026-03-06	RATES.5S30S	1.0499999999999994	0.02999999999999936	2.9411764705881724	computed
4285	2026-03-09	RATES.5S30S	1.0099999999999998	-0.03999999999999959	-3.809523809523773	computed
4286	2026-03-10	CM.COPPER_GOLD_RATIO	0.0011289365709228093	-1.0315106593965749e-05	-0.9054282558924598	computed
4287	2026-03-09	RATES.REAL_TERM_PREM	0	-4.440892098500626e-16	-100	computed
4288	2026-03-10	RATES.US3M	3.71	0	0	fred
4289	2026-03-10	RATES.US2Y	3.57	0.009999999999999787	0.2808988764044884	fred
4290	2026-03-10	RATES.US5Y	3.73	0.020000000000000018	0.539083557951483	fred
4291	2026-03-10	RATES.US10Y	4.15	0.03000000000000025	0.7281553398058312	fred
4292	2026-03-10	RATES.US30Y	4.78	0.0600000000000005	1.2711864406779767	fred
4293	2026-03-11	RATES.2S10S	0.57	-0.010000000000000009	-1.7241379310344844	fred
4294	2026-03-10	RATES.REAL10Y	1.82	0.040000000000000036	2.247191011235957	fred
4295	2026-03-10	RATES.REAL5Y	1.2	0.050000000000000044	4.347826086956526	fred
4296	2026-03-11	RATES.BREAKEVEN	2.36	0.029999999999999805	1.2875536480686611	fred
4297	2026-03-11	RATES.BREAKEVEN5Y	2.58	0.050000000000000266	1.976284584980248	fred
4298	2026-03-10	CREDIT.IG_OAS	0.84	-0.010000000000000009	-1.1764705882352953	fred
4299	2026-03-10	CREDIT.HY_OAS	3.06	-0.1299999999999999	-4.075235109717865	fred
4300	2026-02-01	MACRO.CPI	327.46	\N	\N	fred
4301	2026-03-11	CM.WTI	87.25	3.8000030517578125	4.553628748620172	yfinance
4302	2026-03-11	CM.BRENT	91.9800033569336	4.180000305175781	4.76082022766182	yfinance
4303	2026-03-11	CM.GOLD	5167.39990234375	-62.30029296875	-1.1912784794927858	yfinance
4304	2026-03-11	CM.COPPER	5.8454999923706055	-0.058499813079833984	-0.9908505251952799	yfinance
4305	2026-03-11	CM.NATGAS	3.2090001106262207	0.18900012969970703	6.258282479913235	yfinance
4306	2026-03-11	FX.EURUSD	1.1611299514770508	-0.0005935430526733398	-0.05109159412443589	yfinance
4307	2026-03-11	FX.GBPUSD	1.3419036865234375	-0.0005943775177001953	-0.044273994400485184	yfinance
4308	2026-03-11	FX.USDJPY	158.11399841308594	0.2659912109375	0.16851097182168268	yfinance
4309	2026-03-11	FX.DXY	99.2300033569336	0.40000152587890625	0.4047369406738354	yfinance
4310	2026-03-11	EQ.XLE	56.97999954223633	1.3800010681152344	2.482016377675897	yfinance
4311	2026-03-11	EQ.XLF	49.63999938964844	-0.4200019836425781	-0.8389971476642143	yfinance
4312	2026-03-11	EQ.XLU	46.16999816894531	-0.3900032043457031	-0.8376357234590356	yfinance
4313	2026-03-11	EQ.EEM	58.83000183105469	0.15000152587890625	0.2556263208909281	yfinance
4314	2026-03-11	EQ.GLD	476.239990234375	-1.6199951171875	-0.3390104145245948	yfinance
4315	2026-03-11	EQ.SLV	77.91000366210938	-2.17999267578125	-2.721928799427219	yfinance
4316	2026-03-11	EQ.XLK	140.42999267578125	0.6699981689453125	0.4793919542638087	yfinance
4317	2026-03-11	EQ.XLV	152.85000610351562	-0.29998779296875	-0.19587842306511274	yfinance
4318	2026-03-11	EQ.XLY	114.13999938964844	-0.3000030517578125	-0.26214876385677754	yfinance
4319	2026-03-11	EQ.XLP	84.58999633789062	-1.1300048828125	-1.3182511277654774	yfinance
4320	2026-03-11	EQ.XLI	169.49000549316406	-0.529998779296875	-0.3117273061865943	yfinance
4321	2026-03-11	EQ.XLB	49.84000015258789	-0.04000091552734375	-0.0801942956511152	yfinance
4322	2026-03-11	FX.AUDUSD	0.712100088596344	0.005241453647613525	0.7415137042208866	yfinance
4323	2026-03-11	FX.EURGBP	0.8651900291442871	-0.00012999773025512695	-0.015023081197446338	yfinance
4324	2026-03-11	EQ.SPX	6775.7998046875	-5.68017578125	-0.08376012017449581	yfinance
4325	2026-03-11	EQ.SX7E	5794.68017578125	-42.48974609375	-0.7279168957291817	yfinance
4326	2026-03-11	EQ.VIX	24.229999542236328	-0.7000007629394531	-2.8078650395929765	yfinance
4327	2026-03-11	EQ.SPY	676.3300170898438	-0.8499755859375	-0.12551693717041776	yfinance
4328	2026-03-11	EQ.LQD	109.16000366210938	-0.899993896484375	-0.8177302529969949	yfinance
4329	2026-03-11	EQ.HYG	79.86000061035156	-0.18000030517578125	-0.22488793492862408	yfinance
4330	2026-03-10	EQ.IEAC	119.55000305175781	0.4900054931640625	0.41156182026873717	yfinance
4331	2026-03-11	EQ.IEAC	118.83000183105469	-0.720001220703125	-0.6022594749674818	yfinance
4332	2026-03-11	EQ.IWM	252.85000610351562	-0.5099945068359375	-0.20129243195743055	yfinance
4333	2026-03-11	CM.IRON_ORE	103.52999877929688	0.30999755859375	0.30032702473130074	yfinance
4334	2026-03-11	EQ.STOXX600	602.5399780273438	-3.58001708984375	-0.5906449413785777	yfinance
4335	2026-03-11	EQ.DAX	23640.029296875	-328.6015625	-1.3709650936172353	yfinance
4336	2026-03-11	EQ.FTSE	10353.7998046875	-58.400390625	-0.5608842466483832	yfinance
4337	2026-03-11	EQ.NIKKEI	55025.37109375	776.98046875	1.4322645516269636	yfinance
4338	2026-03-10	EQ.IHYG	92.87000274658203	0.5100021362304688	0.5521894032700001	yfinance
4339	2026-03-11	EQ.IHYG	92.44999694824219	-0.42000579833984375	-0.45225130388542123	yfinance
4340	2026-03-11	CM.SILVER	85.06500244140625	-4.017997741699219	-4.510397868774551	yfinance
4341	2026-03-11	EQ.MOVE	78.58999633789062	2.2599945068359375	2.960820716129557	yfinance
4342	2026-03-11	FX.USDCHF	0.778577983379364	0.0006979703903198242	0.08972725596044522	yfinance
4343	2026-03-11	CM.WHEAT	588.5	3.75	0.6412997007268063	yfinance
4344	2026-03-10	RATES.5S30S	1.0500000000000003	0.04000000000000048	3.9603960396040088	computed
4345	2026-03-10	CREDIT.IG_HY_DIFF	2.22	-0.11999999999999966	-5.128205128205114	computed
4346	2026-03-11	CM.COPPER_GOLD_RATIO	0.0011312265554905656	2.2899845677562536e-06	0.20284439593309944	computed
4347	2026-03-10	RATES.REAL_TERM_PREM	0	0	\N	computed
5613	2025-03-21	EQ.LVMH	588.3892	-1.95318603515625	-0.33085646757656245	yfinance_direct
5614	2025-03-24	EQ.LVMH	582.3344	-6.0548095703125	-1.0290483496710483	yfinance_direct
5615	2025-03-25	EQ.LVMH	584.2876	1.95318603515625	0.3354062538943904	yfinance_direct
4349	2024-03-20	EQ.AAPL	177.0586	2.566650390625	1.4709276066076662	yfinance_direct
4350	2024-03-21	EQ.AAPL	169.8244	-7.23419189453125	-4.08576116972214	yfinance_direct
4351	2024-03-22	EQ.AAPL	170.7263	0.90185546875	0.5310517086263467	yfinance_direct
4352	2024-03-25	EQ.AAPL	169.3092	-1.4171142578125	-0.8300504874687599	yfinance_direct
4353	2024-03-26	EQ.AAPL	168.1795	-1.12969970703125	-0.6672407554359312	yfinance_direct
4354	2024-03-27	EQ.AAPL	171.747	3.5675048828125	2.1212488802881633	yfinance_direct
4355	2024-03-28	EQ.AAPL	169.9334	-1.81353759765625	-1.05593575611946	yfinance_direct
4356	2024-04-01	EQ.AAPL	168.4965	-1.4369049072265625	-0.845569316094443	yfinance_direct
4357	2024-04-02	EQ.AAPL	167.3172	-1.1792755126953125	-0.6998812234957965	yfinance_direct
4358	2024-04-03	EQ.AAPL	168.1199	0.802703857421875	0.4797496247937699	yfinance_direct
4359	2024-04-04	EQ.AAPL	167.2975	-0.8224639892578125	-0.4892126083088906	yfinance_direct
4360	2024-04-05	EQ.AAPL	168.0506	0.7530975341796875	0.45015472444018645	yfinance_direct
4361	2024-04-08	EQ.AAPL	166.9308	-1.1197967529296875	-0.6663450573634956	yfinance_direct
4362	2024-04-09	EQ.AAPL	168.1398	1.209014892578125	0.7242611866790202	yfinance_direct
4363	2024-04-10	EQ.AAPL	166.2668	-1.8729705810546875	-1.1139364800198925	yfinance_direct
4364	2024-04-11	EQ.AAPL	173.4613	7.19451904296875	4.327092194962714	yfinance_direct
4365	2024-04-12	EQ.AAPL	174.9578	1.4964141845703125	0.8626787402457239	yfinance_direct
4366	2024-04-15	EQ.AAPL	171.1325	-3.825225830078125	-2.1863710130932827	yfinance_direct
4367	2024-04-16	EQ.AAPL	167.8524	-3.280120849609375	-1.9167137301742558	yfinance_direct
4368	2024-04-17	EQ.AAPL	166.4849	-1.3675537109375	-0.8147357872130916	yfinance_direct
4369	2024-04-18	EQ.AAPL	165.5335	-0.9513702392578125	-0.5714454879003757	yfinance_direct
4370	2024-04-19	EQ.AAPL	163.5119	-2.021575927734375	-1.2212488787520155	yfinance_direct
4371	2024-04-22	EQ.AAPL	164.3443	0.8324127197265625	0.5090838236242404	yfinance_direct
4372	2024-04-23	EQ.AAPL	165.3948	1.050445556640625	0.6391735922387788	yfinance_direct
4373	2024-04-24	EQ.AAPL	167.4957	2.10089111328125	1.2702282211269498	yfinance_direct
4374	2024-04-25	EQ.AAPL	168.3578	0.86212158203125	0.5147127684113213	yfinance_direct
4375	2024-04-26	EQ.AAPL	167.7731	-0.5846710205078125	-0.3472788679127631	yfinance_direct
4376	2024-04-29	EQ.AAPL	171.9352	4.1621246337890625	2.4808054511891076	yfinance_direct
4377	2024-04-30	EQ.AAPL	168.7939	-3.141387939453125	-1.827076234288621	yfinance_direct
4378	2024-05-01	EQ.AAPL	167.7731	-1.0207366943359375	-0.6047238519648305	yfinance_direct
4379	2024-05-02	EQ.AAPL	171.4695	3.6963653564453125	2.203192872076025	yfinance_direct
4380	2024-05-03	EQ.AAPL	181.7261	10.25665283203125	5.981619986929389	yfinance_direct
4381	2024-05-06	EQ.AAPL	180.0712	-1.6549530029296875	-0.9106851915479306	yfinance_direct
4382	2024-05-07	EQ.AAPL	180.755	0.6837921142578125	0.37973433933741174	yfinance_direct
4383	2024-05-08	EQ.AAPL	181.0919	0.336944580078125	0.18640957531674518	yfinance_direct
4384	2024-05-09	EQ.AAPL	182.9054	1.813507080078125	1.0014290480989279	yfinance_direct
4385	2024-05-10	EQ.AAPL	181.6452	-1.2602691650390625	-0.6890277628308927	yfinance_direct
4386	2024-05-13	EQ.AAPL	184.8504	3.205230712890625	1.764556109445186	yfinance_direct
4387	2024-05-14	EQ.AAPL	185.9915	1.141143798828125	0.6173337334096615	yfinance_direct
4388	2024-05-15	EQ.AAPL	188.264	2.272430419921875	1.2217924134276565	yfinance_direct
4389	2024-05-16	EQ.AAPL	188.383	0.11907958984375	0.06325139910490031	yfinance_direct
4390	2024-05-17	EQ.AAPL	188.4128	0.0297698974609375	0.01580285424981356	yfinance_direct
4391	2024-05-20	EQ.AAPL	189.5738	1.1610107421875	0.6162058377582702	yfinance_direct
4392	2024-05-21	EQ.AAPL	190.8738	1.2999725341796875	0.6857342012297256	yfinance_direct
4393	2024-05-22	EQ.AAPL	189.4349	-1.43890380859375	-0.7538508950080761	yfinance_direct
4394	2024-05-23	EQ.AAPL	185.4458	-3.9891204833984375	-2.1058002924733814	yfinance_direct
4395	2024-05-24	EQ.AAPL	188.522	3.076202392578125	1.6588150747273966	yfinance_direct
4396	2024-05-28	EQ.AAPL	188.5319	0.0099334716796875	0.0052691320484960875	yfinance_direct
4397	2024-05-29	EQ.AAPL	188.8296	0.2976837158203125	0.15789566972198174	yfinance_direct
4398	2024-05-30	EQ.AAPL	189.8219	0.9923248291015625	0.5255134165798259	yfinance_direct
4399	2024-05-31	EQ.AAPL	190.7745	0.952606201171875	0.5018420569688402	yfinance_direct
4400	2024-06-03	EQ.AAPL	192.5409	1.7663726806640625	0.9258954878101745	yfinance_direct
4401	2024-06-04	EQ.AAPL	192.8584	0.3175506591796875	0.16492634542048254	yfinance_direct
4402	2024-06-05	EQ.AAPL	194.3667	1.50830078125	0.7820766092966066	yfinance_direct
4403	2024-06-06	EQ.AAPL	192.9874	-1.3793182373046875	-0.7096472379260856	yfinance_direct
4404	2024-06-07	EQ.AAPL	195.3789	2.3914947509765625	1.239197180434839	yfinance_direct
4405	2024-06-10	EQ.AAPL	191.6379	-3.7410430908203125	-1.9147628935253502	yfinance_direct
4406	2024-06-11	EQ.AAPL	205.5602	13.92230224609375	7.264901052457247	yfinance_direct
4407	2024-06-12	EQ.AAPL	211.4347	5.8745574951171875	2.857828532811861	yfinance_direct
4408	2024-06-13	EQ.AAPL	212.5958	1.161041259765625	0.5491251200602284	yfinance_direct
4409	2024-06-14	EQ.AAPL	210.8592	-1.7365570068359375	-0.8168351279513621	yfinance_direct
4410	2024-06-17	EQ.AAPL	215.0071	4.1479034423828125	1.967143478446501	yfinance_direct
4411	2024-06-18	EQ.AAPL	212.6454	-2.3617095947265625	-1.0984331730125394	yfinance_direct
4412	2024-06-20	EQ.AAPL	208.0708	-4.57464599609375	-2.1513024247395043	yfinance_direct
4413	2024-06-21	EQ.AAPL	205.8976	-2.1731719970703125	-1.0444388677546688	yfinance_direct
4414	2024-06-24	EQ.AAPL	206.5426	0.6450042724609375	0.3132645926378263	yfinance_direct
4415	2024-06-25	EQ.AAPL	207.4655	0.922882080078125	0.446824078293283	yfinance_direct
4416	2024-06-26	EQ.AAPL	211.6134	4.1478729248046875	1.9993074666946347	yfinance_direct
4417	2024-06-27	EQ.AAPL	212.4568	0.8434906005859375	0.39859988536440644	yfinance_direct
4418	2024-06-28	EQ.AAPL	209.0036	-3.453277587890625	-1.6254018724505463	yfinance_direct
4419	2024-07-01	EQ.AAPL	215.0865	6.08294677734375	2.910451128247712	yfinance_direct
4420	2024-07-02	EQ.AAPL	218.5795	3.4929962158203125	1.6239958966820873	yfinance_direct
4421	2024-07-03	EQ.AAPL	219.8497	1.2701568603515625	0.5810960230095623	yfinance_direct
4422	2024-07-05	EQ.AAPL	224.6029	4.7532501220703125	2.1620455983411517	yfinance_direct
4423	2024-07-08	EQ.AAPL	226.0716	1.4686431884765625	0.6538842794191708	yfinance_direct
4424	2024-07-09	EQ.AAPL	226.9249	0.8533782958984375	0.37748148500124123	yfinance_direct
4425	2024-07-10	EQ.AAPL	231.1919	4.266998291015625	1.880356673486979	yfinance_direct
4426	2024-07-11	EQ.AAPL	225.8235	-5.36846923828125	-2.322083214119888	yfinance_direct
4427	2024-07-12	EQ.AAPL	228.7707	2.94720458984375	1.3050922368201718	yfinance_direct
4428	2024-07-15	EQ.AAPL	232.6011	3.8303985595703125	1.6743398377145167	yfinance_direct
4429	2024-07-16	EQ.AAPL	233.0179	0.416778564453125	0.17918170234294148	yfinance_direct
4430	2024-07-17	EQ.AAPL	227.1234	-5.8944244384765625	-2.5296020747220003	yfinance_direct
4431	2024-07-18	EQ.AAPL	222.4595	-4.6639404296875	-2.053482753266915	yfinance_direct
4432	2024-07-19	EQ.AAPL	222.5885	0.1290130615234375	0.05799395779096179	yfinance_direct
4433	2024-07-22	EQ.AAPL	222.2412	-0.3473052978515625	-0.1560302065595617	yfinance_direct
4434	2024-07-23	EQ.AAPL	223.2831	1.0419158935546875	0.4688221238068579	yfinance_direct
4435	2024-07-24	EQ.AAPL	216.8628	-6.4203338623046875	-2.875422962845421	yfinance_direct
4436	2024-07-25	EQ.AAPL	215.8208	-1.04193115234375	-0.4804564265690912	yfinance_direct
4437	2024-07-26	EQ.AAPL	216.2872	0.466400146484375	0.2161052344680991	yfinance_direct
4438	2024-07-29	EQ.AAPL	216.5651	0.2778472900390625	0.12846216976407307	yfinance_direct
4439	2024-07-30	EQ.AAPL	217.1208	0.5557098388671875	0.2566017582141944	yfinance_direct
4440	2024-07-31	EQ.AAPL	220.3756	3.254791259765625	1.4990692749410386	yfinance_direct
4441	2024-08-01	EQ.AAPL	216.6842	-3.691436767578125	-1.6750660462308036	yfinance_direct
4442	2024-08-02	EQ.AAPL	218.1727	1.488494873046875	0.6869421763694286	yfinance_direct
4443	2024-08-05	EQ.AAPL	207.6639	-10.508712768554688	-4.81669568321469	yfinance_direct
4444	2024-08-06	EQ.AAPL	205.6396	-2.02435302734375	-0.974821638824277	yfinance_direct
4445	2024-08-07	EQ.AAPL	208.2097	2.57012939453125	1.249822287137091	yfinance_direct
4446	2024-08-08	EQ.AAPL	211.6729	3.4632110595703125	1.6633282600105297	yfinance_direct
4447	2024-08-09	EQ.AAPL	214.5804	2.9075164794921875	1.3735892014797657	yfinance_direct
4448	2024-08-12	EQ.AAPL	216.1104	1.529937744140625	0.7129902954928284	yfinance_direct
4449	2024-08-13	EQ.AAPL	219.826	3.7155914306640625	1.7193026058726217	yfinance_direct
4450	2024-08-14	EQ.AAPL	220.2731	0.44708251953125	0.20338020680226968	yfinance_direct
4451	2024-08-15	EQ.AAPL	223.2535	2.9804229736328125	1.353058348281687	yfinance_direct
4452	2024-08-16	EQ.AAPL	224.5748	1.321319580078125	0.5918472518204323	yfinance_direct
4453	2024-08-19	EQ.AAPL	224.4158	-0.1589508056640625	-0.07077855871019276	yfinance_direct
4454	2024-08-20	EQ.AAPL	225.0318	0.6159210205078125	0.2744552252460459	yfinance_direct
4455	2024-08-21	EQ.AAPL	224.9225	-0.1092681884765625	-0.04855678336432803	yfinance_direct
4456	2024-08-22	EQ.AAPL	223.0647	-1.8577880859375	-0.8259680916298684	yfinance_direct
4457	2024-08-23	EQ.AAPL	225.3596	2.294921875	1.028814396068506	yfinance_direct
4458	2024-08-26	EQ.AAPL	225.6974	0.3377532958984375	0.149873022646027	yfinance_direct
4459	2024-08-27	EQ.AAPL	226.5419	0.844482421875	0.3741657936311768	yfinance_direct
4460	2024-08-28	EQ.AAPL	225.0119	-1.5299530029296875	-0.6753510960857966	yfinance_direct
4461	2024-08-29	EQ.AAPL	228.2904	3.2784576416015625	1.457015114420277	yfinance_direct
4462	2024-08-30	EQ.AAPL	227.5055	-0.7848358154296875	-0.3437883950512651	yfinance_direct
4463	2024-09-03	EQ.AAPL	221.3162	-6.1893310546875	-2.720518842536015	yfinance_direct
4464	2024-09-04	EQ.AAPL	219.4087	-1.9074859619140625	-0.8618826339636322	yfinance_direct
4465	2024-09-05	EQ.AAPL	220.9287	1.52001953125	0.6927799031515727	yfinance_direct
4466	2024-09-06	EQ.AAPL	219.3789	-1.5498046875	-0.7014952772974198	yfinance_direct
4467	2024-09-09	EQ.AAPL	219.4683	0.0894012451171875	0.040751973017311136	yfinance_direct
4468	2024-09-10	EQ.AAPL	218.6736	-0.794769287109375	-0.3621339161293512	yfinance_direct
4469	2024-09-11	EQ.AAPL	221.2069	2.5333404541015625	1.158503274476971	yfinance_direct
4470	2024-09-12	EQ.AAPL	221.3162	0.1092987060546875	0.04941016827187057	yfinance_direct
4471	2024-09-13	EQ.AAPL	221.048	-0.2682342529296875	-0.12119955221181426	yfinance_direct
4472	2024-09-16	EQ.AAPL	214.9083	-6.1396636962890625	-2.7775254373006777	yfinance_direct
4473	2024-09-17	EQ.AAPL	215.3752	0.4669036865234375	0.2172571580230401	yfinance_direct
4474	2024-09-18	EQ.AAPL	219.2498	3.874542236328125	1.7989731367646653	yfinance_direct
4475	2024-09-19	EQ.AAPL	227.3764	8.126632690429688	3.7065640773812505	yfinance_direct
4476	2024-09-20	EQ.AAPL	226.7108	-0.6656341552734375	-0.2927455042798503	yfinance_direct
4477	2024-09-23	EQ.AAPL	224.992	-1.718719482421875	-0.7581111390202909	yfinance_direct
4478	2024-09-24	EQ.AAPL	225.8862	0.894134521484375	0.39740718902945105	yfinance_direct
4479	2024-09-25	EQ.AAPL	224.8927	-0.9934844970703125	-0.4398164347828202	yfinance_direct
4480	2024-09-26	EQ.AAPL	226.0352	1.14251708984375	0.5080276800315797	yfinance_direct
4481	2024-09-27	EQ.AAPL	226.3034	0.2682342529296875	0.11866923847480967	yfinance_direct
4482	2024-09-30	EQ.AAPL	231.4794	5.1760101318359375	2.2871990885051616	yfinance_direct
4483	2024-10-01	EQ.AAPL	224.7337	-6.745697021484375	-2.9141667331894685	yfinance_direct
4484	2024-10-02	EQ.AAPL	225.3	0.5662689208984375	0.2519732449782732	yfinance_direct
4485	2024-10-03	EQ.AAPL	224.1973	-1.102752685546875	-0.48945965198585706	yfinance_direct
4486	2024-10-04	EQ.AAPL	225.3199	1.1226348876953125	0.5007353165372989	yfinance_direct
4487	2024-10-07	EQ.AAPL	220.2432	-5.07666015625	-2.2530900043442736	yfinance_direct
4488	2024-10-08	EQ.AAPL	224.2966	4.053375244140625	1.8404084672839789	yfinance_direct
4489	2024-10-09	EQ.AAPL	228.042	3.7453765869140625	1.6698319664277084	yfinance_direct
4490	2024-10-10	EQ.AAPL	227.5453	-0.496734619140625	-0.21782594265892982	yfinance_direct
4491	2024-10-11	EQ.AAPL	226.065	-1.480255126953125	-0.6505321810578387	yfinance_direct
4492	2024-10-14	EQ.AAPL	229.7905	3.7255096435546875	1.6479815996818445	yfinance_direct
4493	2024-10-15	EQ.AAPL	232.3239	2.53338623046875	1.1024764284141009	yfinance_direct
4494	2024-10-16	EQ.AAPL	230.2674	-2.0565185546875	-0.8851945794639402	yfinance_direct
4495	2024-10-17	EQ.AAPL	230.635	0.3675994873046875	0.15964027891690058	yfinance_direct
4496	2024-10-18	EQ.AAPL	233.4664	2.8314056396484375	1.2276566411911325	yfinance_direct
4497	2024-10-21	EQ.AAPL	234.9367	1.4703216552734375	0.6297787392307928	yfinance_direct
4498	2024-10-22	EQ.AAPL	234.3208	-0.615936279296875	-0.26217115595098517	yfinance_direct
4499	2024-10-23	EQ.AAPL	229.254	-5.066741943359375	-2.1623102116205795	yfinance_direct
4500	2024-10-24	EQ.AAPL	229.0653	-0.1887359619140625	-0.08232612674110207	yfinance_direct
4501	2024-10-25	EQ.AAPL	229.8998	0.8345184326171875	0.3643146563257997	yfinance_direct
4502	2024-10-28	EQ.AAPL	231.8768	1.9770050048828125	0.8599419886778232	yfinance_direct
4503	2024-10-29	EQ.AAPL	232.1451	0.2682342529296875	0.11567963446841165	yfinance_direct
4504	2024-10-30	EQ.AAPL	228.5984	-3.54669189453125	-1.5277913071096103	yfinance_direct
4505	2024-10-31	EQ.AAPL	224.4357	-4.16265869140625	-1.8209486389209248	yfinance_direct
4506	2024-11-01	EQ.AAPL	221.4553	-2.9804229736328125	-1.3279629670170237	yfinance_direct
4507	2024-11-04	EQ.AAPL	220.5612	-0.8941192626953125	-0.40374710274229286	yfinance_direct
4508	2024-11-05	EQ.AAPL	221.9918	1.43060302734375	0.6486196596593937	yfinance_direct
4509	2024-11-06	EQ.AAPL	221.2665	-0.725250244140625	-0.32670142500384236	yfinance_direct
4510	2024-11-07	EQ.AAPL	225.9955	4.72894287109375	2.1372158266901926	yfinance_direct
4511	2024-11-08	EQ.AAPL	225.7269	-0.268524169921875	-0.11881839501586608	yfinance_direct
4512	2024-11-11	EQ.AAPL	223.0117	-2.715179443359375	-1.2028602253461715	yfinance_direct
4513	2024-11-12	EQ.AAPL	223.0117	0	0	yfinance_direct
4514	2024-11-13	EQ.AAPL	223.8969	0.885162353515625	0.39691287854684865	yfinance_direct
4515	2024-11-14	EQ.AAPL	226.9801	3.0831756591796875	1.3770514460679215	yfinance_direct
4516	2024-11-15	EQ.AAPL	223.7776	-3.2025146484375	-1.410923172517357	yfinance_direct
4517	2024-11-18	EQ.AAPL	226.7812	3.00360107421875	1.3422261395069934	yfinance_direct
4518	2024-11-19	EQ.AAPL	227.0397	0.2585601806640625	0.11401307103172444	yfinance_direct
4519	2024-11-20	EQ.AAPL	227.7558	0.7161102294921875	0.31541185202828415	yfinance_direct
4520	2024-11-21	EQ.AAPL	227.2785	-0.477386474609375	-0.20960448960677017	yfinance_direct
4521	2024-11-22	EQ.AAPL	228.6211	1.3426513671875	0.5907517065716562	yfinance_direct
4522	2024-11-25	EQ.AAPL	231.6048	2.9836883544921875	1.3050799934565462	yfinance_direct
4523	2024-11-26	EQ.AAPL	233.7829	2.1781158447265625	0.9404450467017321	yfinance_direct
4524	2024-11-27	EQ.AAPL	233.6536	-0.129302978515625	-0.05530899446041977	yfinance_direct
4525	2024-11-29	EQ.AAPL	236.0406	2.386962890625	1.0215818571262603	yfinance_direct
4526	2024-12-02	EQ.AAPL	238.2883	2.247711181640625	0.9522562803204183	yfinance_direct
4527	2024-12-03	EQ.AAPL	241.3317	3.0433807373046875	1.27718437615283	yfinance_direct
4528	2024-12-04	EQ.AAPL	241.6897	0.3580474853515625	0.14836324329573913	yfinance_direct
4529	2024-12-05	EQ.AAPL	241.7195	0.0298309326171875	0.012342657163851837	yfinance_direct
4530	2024-12-06	EQ.AAPL	241.5206	-0.1988983154296875	-0.08228474726746463	yfinance_direct
4531	2024-12-09	EQ.AAPL	245.4094	3.888763427734375	1.6101163631185338	yfinance_direct
4532	2024-12-10	EQ.AAPL	246.4239	1.0144500732421875	0.4133704894022322	yfinance_direct
4533	2024-12-11	EQ.AAPL	245.1508	-1.2730255126953125	-0.5165999427603127	yfinance_direct
4534	2024-12-12	EQ.AAPL	246.6128	1.462005615234375	0.5963698334485338	yfinance_direct
4535	2024-12-13	EQ.AAPL	246.7819	0.1690826416015625	0.06856197854983341	yfinance_direct
4536	2024-12-16	EQ.AAPL	249.6761	2.8941497802734375	1.1727559960675442	yfinance_direct
4537	2024-12-17	EQ.AAPL	252.1028	2.4267578125	0.9719625117286064	yfinance_direct
4538	2024-12-18	EQ.AAPL	246.7023	-5.4004974365234375	-2.1421804183572855	yfinance_direct
4539	2024-12-19	EQ.AAPL	248.4329	1.7305450439453125	0.7014708913052567	yfinance_direct
4540	2024-12-20	EQ.AAPL	253.1073	4.674468994140625	1.8815822842615058	yfinance_direct
4541	2024-12-23	EQ.AAPL	253.8831	0.7757720947265625	0.30649924163426956	yfinance_direct
4542	2024-12-24	EQ.AAPL	256.7972	2.914093017578125	1.1478088989357444	yfinance_direct
4543	2024-12-26	EQ.AAPL	257.6127	0.815521240234375	0.3175740258363577	yfinance_direct
4544	2024-12-27	EQ.AAPL	254.2014	-3.4113616943359375	-1.3242209221302397	yfinance_direct
4545	2024-12-30	EQ.AAPL	250.8298	-3.3715667724609375	-1.3263369781553784	yfinance_direct
4546	2024-12-31	EQ.AAPL	249.0594	-1.770355224609375	-0.7057993907186243	yfinance_direct
4547	2025-01-02	EQ.AAPL	242.5252	-6.534271240234375	-2.623578943241051	yfinance_direct
4548	2025-01-03	EQ.AAPL	242.0378	-0.4873504638671875	-0.20094840044720913	yfinance_direct
4549	2025-01-06	EQ.AAPL	243.6689	1.6310882568359375	0.6738980762493656	yfinance_direct
4550	2025-01-07	EQ.AAPL	240.8941	-2.7748565673828125	-1.1387815182409313	yfinance_direct
4551	2025-01-08	EQ.AAPL	241.3814	0.487335205078125	0.2023027087774026	yfinance_direct
4552	2025-01-10	EQ.AAPL	235.5632	-5.81817626953125	-2.4103665103563263	yfinance_direct
4553	2025-01-13	EQ.AAPL	233.1265	-2.4367218017578125	-1.0344237233229894	yfinance_direct
4554	2025-01-14	EQ.AAPL	232.0126	-1.1139068603515625	-0.47781221033031557	yfinance_direct
4555	2025-01-15	EQ.AAPL	236.5776	4.5650482177734375	1.9675864345413407	yfinance_direct
4556	2025-01-16	EQ.AAPL	227.0199	-9.557785034179688	-4.040020505210408	yfinance_direct
4557	2025-01-17	EQ.AAPL	228.7305	1.7106781005859375	0.7535367889160708	yfinance_direct
4558	2025-01-21	EQ.AAPL	221.4304	-7.3001556396484375	-3.1915965247426232	yfinance_direct
4559	2025-01-22	EQ.AAPL	222.6139	1.1835479736328125	0.5345011849436119	yfinance_direct
4560	2025-01-23	EQ.AAPL	222.4449	-0.1690673828125	-0.07594645528145222	yfinance_direct
4561	2025-01-24	EQ.AAPL	221.5696	-0.875213623046875	-0.39345195198346894	yfinance_direct
4562	2025-01-27	EQ.AAPL	228.6112	7.0415191650390625	3.1780162343806686	yfinance_direct
4563	2025-01-28	EQ.AAPL	236.9655	8.3543701171875	3.654401695445033	yfinance_direct
4564	2025-01-29	EQ.AAPL	238.0595	1.0940093994140625	0.46167448809457806	yfinance_direct
4565	2025-01-30	EQ.AAPL	236.2992	-1.7603759765625	-0.7394687808264221	yfinance_direct
4566	2025-01-31	EQ.AAPL	234.7178	-1.5813446044921875	-0.6692129497790987	yfinance_direct
4567	2025-02-03	EQ.AAPL	226.7712	-7.9466094970703125	-3.3856012822910655	yfinance_direct
4568	2025-02-04	EQ.AAPL	231.5352	4.7639923095703125	2.1007923869700313	yfinance_direct
4569	2025-02-05	EQ.AAPL	231.207	-0.3282318115234375	-0.14176324319187478	yfinance_direct
4570	2025-02-06	EQ.AAPL	231.9529	0.745941162109375	0.32262918432615867	yfinance_direct
4571	2025-02-07	EQ.AAPL	226.3933	-5.55963134765625	-2.396879312551994	yfinance_direct
4572	2025-02-10	EQ.AAPL	226.6621	0.2688140869140625	0.11873766168292454	yfinance_direct
4573	2025-02-11	EQ.AAPL	231.6105	4.9484405517578125	2.1831795788583506	yfinance_direct
4574	2025-02-12	EQ.AAPL	235.8421	4.2315521240234375	1.8270119405793386	yfinance_direct
4575	2025-02-13	EQ.AAPL	240.4819	4.6397857666015625	1.967327303499378	yfinance_direct
4576	2025-02-14	EQ.AAPL	243.5386	3.0566864013671875	1.2710672820557074	yfinance_direct
4577	2025-02-18	EQ.AAPL	243.4091	-0.1294403076171875	-0.05314982077990705	yfinance_direct
4578	2025-02-19	EQ.AAPL	243.8074	0.3982696533203125	0.16362150092213795	yfinance_direct
4579	2025-02-20	EQ.AAPL	244.7632	0.955841064453125	0.3920476204990049	yfinance_direct
4580	2025-02-21	EQ.AAPL	244.4844	-0.2787933349609375	-0.11390327529114347	yfinance_direct
4581	2025-02-24	EQ.AAPL	246.0277	1.54327392578125	0.6312360618159477	yfinance_direct
4582	2025-02-25	EQ.AAPL	245.968	-0.0597381591796875	-0.024281069473504547	yfinance_direct
4583	2025-02-26	EQ.AAPL	239.317	-6.6510162353515625	-2.704017188348435	yfinance_direct
4584	2025-02-27	EQ.AAPL	236.2702	-3.046722412109375	-1.2730909119658942	yfinance_direct
4585	2025-02-28	EQ.AAPL	240.7905	4.5203094482421875	1.9131946449175372	yfinance_direct
4586	2025-03-03	EQ.AAPL	236.9971	-3.7934722900390625	-1.575424121328867	yfinance_direct
4587	2025-03-04	EQ.AAPL	234.9062	-2.0908966064453125	-0.882245760965861	yfinance_direct
4588	2025-03-05	EQ.AAPL	234.717	-0.1891632080078125	-0.08052713346074857	yfinance_direct
4589	2025-03-06	EQ.AAPL	234.3088	-0.4082183837890625	-0.17391938612496063	yfinance_direct
4590	2025-03-07	EQ.AAPL	238.0326	3.7237701416015625	1.5892575383111154	yfinance_direct
4591	2025-03-10	EQ.AAPL	226.4928	-11.539718627929688	-4.847957993043713	yfinance_direct
4592	2025-03-11	EQ.AAPL	219.8817	-6.6111907958984375	-2.9189402587743336	yfinance_direct
4593	2025-03-12	EQ.AAPL	216.0384	-3.8432464599609375	-1.7478704614326388	yfinance_direct
4594	2025-03-13	EQ.AAPL	208.7701	-7.2683258056640625	-3.364367441753042	yfinance_direct
4595	2025-03-14	EQ.AAPL	212.5636	3.7934722900390625	1.817057444125679	yfinance_direct
4596	2025-03-17	EQ.AAPL	213.0714	0.5077972412109375	0.2388919616684607	yfinance_direct
4597	2025-03-18	EQ.AAPL	211.767	-1.3043212890625	-0.612152355755335	yfinance_direct
4598	2025-03-19	EQ.AAPL	214.306	2.5389251708984375	1.198923734814853	yfinance_direct
4599	2025-03-20	EQ.AAPL	213.1709	-1.135040283203125	-0.529635440418861	yfinance_direct
4600	2025-03-21	EQ.AAPL	217.3228	4.1519012451171875	1.9476865643276853	yfinance_direct
4601	2025-03-24	EQ.AAPL	219.7721	2.4493255615234375	1.1270448352069318	yfinance_direct
4602	2025-03-25	EQ.AAPL	222.779	3.00689697265625	1.368188418138543	yfinance_direct
4603	2025-03-26	EQ.AAPL	220.5687	-2.2103729248046875	-0.9921817374971464	yfinance_direct
4604	2025-03-27	EQ.AAPL	222.8786	2.3099365234375	1.0472641379690115	yfinance_direct
4605	2025-03-28	EQ.AAPL	216.9544	-5.9241790771484375	-2.6580295499861295	yfinance_direct
4606	2025-03-31	EQ.AAPL	221.1661	4.211639404296875	1.941255386974204	yfinance_direct
4607	2025-04-01	EQ.AAPL	222.2215	1.055419921875	0.47720699784929826	yfinance_direct
4608	2025-04-02	EQ.AAPL	222.9184	0.69696044921875	0.31363324781592783	yfinance_direct
4609	2025-04-03	EQ.AAPL	202.3082	-20.610198974609375	-9.245623112531344	yfinance_direct
4610	2025-04-04	EQ.AAPL	187.5625	-14.745712280273438	-7.288735286484348	yfinance_direct
4611	2025-04-07	EQ.AAPL	180.6726	-6.8899688720703125	-3.673424992218578	yfinance_direct
4612	2025-04-08	EQ.AAPL	171.6718	-9.00079345703125	-4.981826446171409	yfinance_direct
4613	2025-04-09	EQ.AAPL	197.9871	26.315322875976562	15.328858759749743	yfinance_direct
4614	2025-04-10	EQ.AAPL	189.5937	-8.3934326171875	-4.2393837760135	yfinance_direct
4615	2025-04-11	EQ.AAPL	197.2901	7.6964569091796875	4.0594484922186425	yfinance_direct
4616	2025-04-14	EQ.AAPL	201.6412	4.3510589599609375	2.2054115342270704	yfinance_direct
4617	2025-04-15	EQ.AAPL	201.2628	-0.3783721923828125	-0.1876462947934869	yfinance_direct
4618	2025-04-16	EQ.AAPL	193.427	-7.8358306884765625	-3.893332799593994	yfinance_direct
4619	2025-04-17	EQ.AAPL	196.1252	2.6982269287109375	1.3949589908199707	yfinance_direct
4620	2025-04-21	EQ.AAPL	192.3218	-3.80340576171875	-1.939274398924911	yfinance_direct
4621	2025-04-22	EQ.AAPL	198.8732	6.55145263671875	3.4065056008802284	yfinance_direct
4622	2025-04-23	EQ.AAPL	203.7121	4.838897705078125	2.4331567070555957	yfinance_direct
4623	2025-04-24	EQ.AAPL	207.4658	3.753631591796875	1.8426155346186455	yfinance_direct
4624	2025-04-25	EQ.AAPL	208.3718	0.9060516357421875	0.4367234247518677	yfinance_direct
4625	2025-04-28	EQ.AAPL	209.2281	0.8562774658203125	0.4109372565147143	yfinance_direct
4626	2025-04-29	EQ.AAPL	210.2935	1.06536865234375	0.5091900341402364	yfinance_direct
4627	2025-04-30	EQ.AAPL	211.5779	1.2843780517578125	0.6107550737411308	yfinance_direct
4628	2025-05-01	EQ.AAPL	212.3943	0.81646728515625	0.3858944988037617	yfinance_direct
4629	2025-05-02	EQ.AAPL	204.4589	-7.9354248046875	-3.736175662959678	yfinance_direct
4630	2025-05-05	EQ.AAPL	198.0269	-6.431976318359375	-3.1458530512295386	yfinance_direct
4631	2025-05-06	EQ.AAPL	197.6486	-0.37835693359375	-0.19106338687361554	yfinance_direct
4632	2025-05-07	EQ.AAPL	195.3984	-2.2501983642578125	-1.1384845754250568	yfinance_direct
4633	2025-05-08	EQ.AAPL	196.633	1.2346343994140625	0.6318550430994124	yfinance_direct
4634	2025-05-09	EQ.AAPL	197.6685	1.035491943359375	0.5266114876452485	yfinance_direct
4635	2025-05-12	EQ.AAPL	210.1505	12.48199462890625	6.314610276877311	yfinance_direct
4636	2025-05-13	EQ.AAPL	212.284	2.133514404296875	1.0152317435524412	yfinance_direct
4637	2025-05-14	EQ.AAPL	211.6858	-0.598175048828125	-0.28178056681582064	yfinance_direct
4638	2025-05-15	EQ.AAPL	210.8085	-0.8773345947265625	-0.4144512789624655	yfinance_direct
4639	2025-05-16	EQ.AAPL	210.6191	-0.189422607421875	-0.08985530429671794	yfinance_direct
4640	2025-05-19	EQ.AAPL	208.1466	-2.4724884033203125	-1.1739148168629276	yfinance_direct
4641	2025-05-20	EQ.AAPL	206.2324	-1.914154052734375	-0.9196183238675725	yfinance_direct
4642	2025-05-21	EQ.AAPL	201.4769	-4.7555389404296875	-2.3059123765283025	yfinance_direct
4643	2025-05-22	EQ.AAPL	200.7491	-0.727783203125	-0.3612241724830277	yfinance_direct
4644	2025-05-23	EQ.AAPL	194.6776	-6.0715179443359375	-3.024430970030844	yfinance_direct
4645	2025-05-27	EQ.AAPL	199.6026	4.925018310546875	2.5298333096887617	yfinance_direct
4646	2025-05-28	EQ.AAPL	199.812	0.2093505859375	0.1048836968231248	yfinance_direct
4647	2025-05-29	EQ.AAPL	199.3434	-0.46856689453125	-0.23450393879254755	yfinance_direct
4648	2025-05-30	EQ.AAPL	200.2407	0.89727783203125	0.4501166855784463	yfinance_direct
4649	2025-06-02	EQ.AAPL	201.0881	0.847412109375	0.4231968185255596	yfinance_direct
4650	2025-06-03	EQ.AAPL	202.6533	1.5652313232421875	0.778380982126353	yfinance_direct
4651	2025-06-04	EQ.AAPL	202.2047	-0.4486236572265625	-0.22137495221588413	yfinance_direct
4652	2025-06-05	EQ.AAPL	200.0213	-2.183349609375	-1.0797720380636848	yfinance_direct
4653	2025-06-06	EQ.AAPL	203.3013	3.279998779296875	1.6398244877140942	yfinance_direct
4654	2025-06-09	EQ.AAPL	200.8388	-2.462493896484375	-1.2112532119803452	yfinance_direct
4655	2025-06-10	EQ.AAPL	202.0551	1.216278076171875	0.6055990446563007	yfinance_direct
4656	2025-06-11	EQ.AAPL	198.1769	-3.8781890869140625	-1.9193718960232546	yfinance_direct
4657	2025-06-12	EQ.AAPL	198.5957	0.418731689453125	0.21129184846335267	yfinance_direct
4658	2025-06-13	EQ.AAPL	195.854	-2.741668701171875	-1.3805280225029801	yfinance_direct
4659	2025-06-16	EQ.AAPL	197.818	1.9640350341796875	1.0028057369385361	yfinance_direct
4660	2025-06-17	EQ.AAPL	195.0465	-2.7715606689453125	-1.401065796413848	yfinance_direct
4661	2025-06-18	EQ.AAPL	195.9836	0.9371337890625	0.4804669485349771	yfinance_direct
4662	2025-06-20	EQ.AAPL	200.3902	4.4066009521484375	2.2484539645457278	yfinance_direct
4663	2025-06-23	EQ.AAPL	200.8887	0.49847412109375	0.2487517486788014	yfinance_direct
4664	2025-06-24	EQ.AAPL	199.6923	-1.1963653564453125	-0.5955364955519906	yfinance_direct
4665	2025-06-25	EQ.AAPL	200.9485	1.256195068359375	0.6290653306879671	yfinance_direct
4666	2025-06-26	EQ.AAPL	200.3902	-0.5583038330078125	-0.27783428520184084	yfinance_direct
4667	2025-06-27	EQ.AAPL	200.47	0.0797576904296875	0.039801193533246446	yfinance_direct
4668	2025-06-30	EQ.AAPL	204.5475	4.07757568359375	2.0340083752480114	yfinance_direct
4669	2025-07-01	EQ.AAPL	207.1895	2.6419677734375	1.2916155765210093	yfinance_direct
4670	2025-07-02	EQ.AAPL	211.7955	4.605987548828125	2.2230796315699433	yfinance_direct
4671	2025-07-03	EQ.AAPL	212.9021	1.1066436767578125	0.5225057886292798	yfinance_direct
4672	2025-07-07	EQ.AAPL	209.313	-3.5890960693359375	-1.6857962234552404	yfinance_direct
4673	2025-07-08	EQ.AAPL	209.3728	0.059814453125	0.02857655443881005	yfinance_direct
4674	2025-07-09	EQ.AAPL	210.4994	1.1265869140625	0.5380768910944529	yfinance_direct
4675	2025-07-10	EQ.AAPL	211.7656	1.2661285400390625	0.6014878555298326	yfinance_direct
4676	2025-07-11	EQ.AAPL	210.5194	-1.246185302734375	-0.588474008428141	yfinance_direct
4677	2025-07-14	EQ.AAPL	207.9871	-2.5323028564453125	-1.2028834934525163	yfinance_direct
4678	2025-07-15	EQ.AAPL	208.4756	0.4885101318359375	0.23487523440753813	yfinance_direct
4679	2025-07-16	EQ.AAPL	209.5224	1.0468292236328125	0.5021351631776427	yfinance_direct
4680	2025-07-17	EQ.AAPL	209.3828	-0.1395721435546875	-0.0666144209188071	yfinance_direct
4681	2025-07-18	EQ.AAPL	210.5393	1.156463623046875	0.552320145423657	yfinance_direct
4682	2025-07-21	EQ.AAPL	211.8354	1.296051025390625	0.6155862513610763	yfinance_direct
4683	2025-07-22	EQ.AAPL	213.7495	1.9141845703125	0.9036190140318532	yfinance_direct
4684	2025-07-23	EQ.AAPL	213.5003	-0.2492523193359375	-0.11660952193308391	yfinance_direct
4685	2025-07-24	EQ.AAPL	213.1115	-0.3888092041015625	-0.18211179209767328	yfinance_direct
4686	2025-07-25	EQ.AAPL	213.2311	0.11962890625	0.056134425911651	yfinance_direct
4687	2025-07-28	EQ.AAPL	213.4006	0.1695098876953125	0.07949585217564169	yfinance_direct
4688	2025-07-29	EQ.AAPL	210.629	-2.771575927734375	-1.2987665800312225	yfinance_direct
4689	2025-07-30	EQ.AAPL	208.4158	-2.2132720947265625	-1.050791503924467	yfinance_direct
4690	2025-07-31	EQ.AAPL	206.9403	-1.475494384765625	-0.7079571638254082	yfinance_direct
4691	2025-08-01	EQ.AAPL	201.766	-5.17425537109375	-2.500361671306333	yfinance_direct
4692	2025-08-04	EQ.AAPL	202.7331	0.9670562744140625	0.4792959023176241	yfinance_direct
4693	2025-08-05	EQ.AAPL	202.3044	-0.4287109375	-0.21146570738387582	yfinance_direct
4694	2025-08-06	EQ.AAPL	212.603	10.298660278320312	5.09067620620839	yfinance_direct
4695	2025-08-07	EQ.AAPL	219.3625	6.759429931640625	3.179366736256089	yfinance_direct
4696	2025-08-08	EQ.AAPL	228.6542	9.291748046875	4.235796846134893	yfinance_direct
4697	2025-08-11	EQ.AAPL	226.7478	-1.9063873291015625	-0.8337425180589603	yfinance_direct
4698	2025-08-12	EQ.AAPL	229.2131	2.4652862548828125	1.0872370357086019	yfinance_direct
4699	2025-08-13	EQ.AAPL	232.8861	3.6730194091796875	1.602447391142553	yfinance_direct
4700	2025-08-14	EQ.AAPL	232.3372	-0.5489501953125	-0.2357161460252876	yfinance_direct
4701	2025-08-15	EQ.AAPL	231.1494	-1.1877593994140625	-0.5112222817020567	yfinance_direct
4702	2025-08-18	EQ.AAPL	230.4507	-0.69866943359375	-0.30225879499951414	yfinance_direct
4703	2025-08-19	EQ.AAPL	230.1214	-0.3293609619140625	-0.14292032878627964	yfinance_direct
4704	2025-08-20	EQ.AAPL	225.58	-4.541351318359375	-1.9734590701623573	yfinance_direct
4705	2025-08-21	EQ.AAPL	224.4721	-1.1078948974609375	-0.49113163338353083	yfinance_direct
4706	2025-08-22	EQ.AAPL	227.3267	2.8545684814453125	1.271680536327699	yfinance_direct
4707	2025-08-25	EQ.AAPL	226.7279	-0.598846435546875	-0.2634298654397348	yfinance_direct
4708	2025-08-26	EQ.AAPL	228.8738	2.145904541015625	0.9464670754514637	yfinance_direct
4709	2025-08-27	EQ.AAPL	230.0515	1.177764892578125	0.5145914812595724	yfinance_direct
4710	2025-08-28	EQ.AAPL	232.1176	2.0660552978515625	0.8980837064874527	yfinance_direct
4711	2025-08-29	EQ.AAPL	231.6984	-0.4192047119140625	-0.18060015285242798	yfinance_direct
4712	2025-09-02	EQ.AAPL	229.283	-2.4153900146484375	-1.042471690862806	yfinance_direct
4713	2025-09-03	EQ.AAPL	238.0163	8.733352661132812	3.80898412049814	yfinance_direct
4714	2025-09-04	EQ.AAPL	239.3239	1.3075103759765625	0.549336387616894	yfinance_direct
4715	2025-09-05	EQ.AAPL	239.234	-0.08984375	-0.03754065842030337	yfinance_direct
4716	2025-09-08	EQ.AAPL	237.4275	-1.806549072265625	-0.7551389041256655	yfinance_direct
4717	2025-09-09	EQ.AAPL	233.9042	-3.523284912109375	-1.4839416284501987	yfinance_direct
4718	2025-09-10	EQ.AAPL	226.3586	-7.545623779296875	-3.225946602106419	yfinance_direct
4719	2025-09-11	EQ.AAPL	229.5924	3.2338409423828125	1.4286365271970984	yfinance_direct
4720	2025-09-12	EQ.AAPL	233.6247	4.0323333740234375	1.756300955560162	yfinance_direct
4721	2025-09-15	EQ.AAPL	236.2497	2.624969482421875	1.123583763910905	yfinance_direct
4722	2025-09-16	EQ.AAPL	237.6969	1.4472503662109375	0.6125935389198119	yfinance_direct
4723	2025-09-17	EQ.AAPL	238.5354	0.838409423828125	0.3527220020250734	yfinance_direct
4724	2025-09-18	EQ.AAPL	237.4275	-1.1078948974609375	-0.46445731252398426	yfinance_direct
4725	2025-09-19	EQ.AAPL	245.033	7.605499267578125	3.2032938720104043	yfinance_direct
4726	2025-09-22	EQ.AAPL	255.5928	10.559860229492188	4.309567281585804	yfinance_direct
4727	2025-09-23	EQ.AAPL	253.946	-1.6468505859375	-0.6443258425658267	yfinance_direct
4728	2025-09-24	EQ.AAPL	251.83	-2.115966796875	-0.8332350414174994	yfinance_direct
4729	2025-09-25	EQ.AAPL	256.3813	4.5513153076171875	1.8072966979806204	yfinance_direct
4730	2025-09-26	EQ.AAPL	254.974	-1.4073028564453125	-0.5489100657377965	yfinance_direct
4731	2025-09-29	EQ.AAPL	253.946	-1.028045654296875	-0.4031962461707757	yfinance_direct
4732	2025-09-30	EQ.AAPL	254.1456	0.1996307373046875	0.0786115008571676	yfinance_direct
4733	2025-10-01	EQ.AAPL	254.964	0.8184356689453125	0.32203416899189863	yfinance_direct
4734	2025-10-02	EQ.AAPL	256.6408	1.6768035888671875	0.6576627910059551	yfinance_direct
4735	2025-10-03	EQ.AAPL	257.5291	0.8883056640625	0.34612794628809646	yfinance_direct
4736	2025-10-06	EQ.AAPL	256.2017	-1.32745361328125	-0.5154576259537145	yfinance_direct
4737	2025-10-07	EQ.AAPL	255.9921	-0.2096099853515625	-0.0818144426761095	yfinance_direct
4738	2025-10-08	EQ.AAPL	257.5691	1.5769805908203125	0.6160270999708704	yfinance_direct
4739	2025-10-09	EQ.AAPL	253.5567	-4.012359619140625	-1.5577801150541888	yfinance_direct
4740	2025-10-10	EQ.AAPL	244.8034	-8.7532958984375	-3.452204513280663	yfinance_direct
4741	2025-10-13	EQ.AAPL	247.1889	2.3854522705078125	0.9744359001400946	yfinance_direct
4742	2025-10-14	EQ.AAPL	247.2986	0.1097869873046875	0.044414213560699536	yfinance_direct
4743	2025-10-15	EQ.AAPL	248.8656	1.5670013427734375	0.6336473629484214	yfinance_direct
4744	2025-10-16	EQ.AAPL	246.9792	-1.8863983154296875	-0.7579986804138579	yfinance_direct
4745	2025-10-17	EQ.AAPL	251.81	4.830780029296875	1.9559457191237481	yfinance_direct
4746	2025-10-20	EQ.AAPL	261.7411	9.93109130859375	3.9438823721466805	yfinance_direct
4747	2025-10-21	EQ.AAPL	262.2701	0.52899169921875	0.20210492736569974	yfinance_direct
4748	2025-10-22	EQ.AAPL	257.9583	-4.311767578125	-1.6440179021178216	yfinance_direct
4749	2025-10-23	EQ.AAPL	259.0862	1.1278076171875	0.43720532620100444	yfinance_direct
4750	2025-10-24	EQ.AAPL	262.32	3.233856201171875	1.2481779466614682	yfinance_direct
4751	2025-10-27	EQ.AAPL	268.2986	5.978607177734375	2.279127405766277	yfinance_direct
4752	2025-10-28	EQ.AAPL	268.4883	0.18963623046875	0.07068103233435427	yfinance_direct
4753	2025-10-29	EQ.AAPL	269.1869	0.69866943359375	0.26022346664623736	yfinance_direct
4754	2025-10-30	EQ.AAPL	270.8837	1.696746826171875	0.6303229091240542	yfinance_direct
4755	2025-10-31	EQ.AAPL	269.8557	-1.02801513671875	-0.3795042898427681	yfinance_direct
4756	2025-11-03	EQ.AAPL	268.5381	-1.3175048828125	-0.4882257880291271	yfinance_direct
4757	2025-11-04	EQ.AAPL	269.5263	0.988128662109375	0.3679658451691002	yfinance_direct
4758	2025-11-05	EQ.AAPL	269.6261	0.099822998046875	0.0370364625162353	yfinance_direct
4759	2025-11-06	EQ.AAPL	269.2568	-0.36932373046875	-0.1369762542800835	yfinance_direct
4760	2025-11-07	EQ.AAPL	267.9593	-1.297515869140625	-0.48188791892468397	yfinance_direct
4761	2025-11-10	EQ.AAPL	269.1781	1.2188720703125	0.4548721603090671	yfinance_direct
4762	2025-11-11	EQ.AAPL	274.9927	5.814544677734375	2.1601103529091383	yfinance_direct
4763	2025-11-12	EQ.AAPL	273.2144	-1.7783203125	-0.6466791551621581	yfinance_direct
4764	2025-11-13	EQ.AAPL	272.6949	-0.519500732421875	-0.1901440103798993	yfinance_direct
4765	2025-11-14	EQ.AAPL	272.1553	-0.539520263671875	-0.19784761402760734	yfinance_direct
4766	2025-11-17	EQ.AAPL	267.21	-4.94537353515625	-1.8171143125813385	yfinance_direct
4767	2025-11-18	EQ.AAPL	267.19	-0.01995849609375	-0.007469218596389923	yfinance_direct
4768	2025-11-19	EQ.AAPL	268.3089	1.118927001953125	0.41877577444107456	yfinance_direct
4769	2025-11-20	EQ.AAPL	266.0011	-2.307830810546875	-0.8601393980195741	yfinance_direct
4770	2025-11-21	EQ.AAPL	271.2362	5.235076904296875	1.9680658956688621	yfinance_direct
4771	2025-11-24	EQ.AAPL	275.6621	4.4259033203125	1.631752590357169	yfinance_direct
4772	2025-11-25	EQ.AAPL	276.7111	1.04901123046875	0.38054245067611214	yfinance_direct
4773	2025-11-26	EQ.AAPL	277.2905	0.579437255859375	0.20940152983219093	yfinance_direct
4774	2025-11-28	EQ.AAPL	278.5893	1.298797607421875	0.4683887400927291	yfinance_direct
4775	2025-12-01	EQ.AAPL	282.8354	4.24603271484375	1.5241189573893217	yfinance_direct
4776	2025-12-02	EQ.AAPL	285.9225	3.08709716796875	1.09148205282528	yfinance_direct
4777	2025-12-03	EQ.AAPL	283.8844	-2.0380859375	-0.7128107299873937	yfinance_direct
4778	2025-12-04	EQ.AAPL	280.4376	-3.44677734375	-1.2141483369261634	yfinance_direct
4779	2025-12-05	EQ.AAPL	278.5194	-1.918212890625	-0.6840070477014824	yfinance_direct
4780	2025-12-08	EQ.AAPL	277.6302	-0.88916015625	-0.3192453467766421	yfinance_direct
4781	2025-12-09	EQ.AAPL	276.9209	-0.7093505859375	-0.25550193698476276	yfinance_direct
4782	2025-12-10	EQ.AAPL	278.5194	1.5985107421875	0.5772445948890159	yfinance_direct
4783	2025-12-11	EQ.AAPL	277.7701	-0.749298095703125	-0.2690290705452668	yfinance_direct
4784	2025-12-12	EQ.AAPL	278.0199	0.249786376953125	0.08992558753764295	yfinance_direct
4785	2025-12-15	EQ.AAPL	273.8537	-4.1661376953125	-1.498503592968506	yfinance_direct
4786	2025-12-16	EQ.AAPL	274.3533	0.499542236328125	0.18241206270945376	yfinance_direct
4787	2025-12-17	EQ.AAPL	271.5859	-2.76739501953125	-1.0086976563313403	yfinance_direct
4788	2025-12-18	EQ.AAPL	271.9355	0.34967041015625	0.1287513234148294	yfinance_direct
4789	2025-12-19	EQ.AAPL	273.4142	1.4786376953125	0.543745645725449	yfinance_direct
4790	2025-12-22	EQ.AAPL	270.7167	-2.697509765625	-0.9866019825797646	yfinance_direct
4791	2025-12-23	EQ.AAPL	272.1054	1.388702392578125	0.512972610047026	yfinance_direct
4792	2025-12-24	EQ.AAPL	273.554	1.448638916015625	0.5323815835382846	yfinance_direct
4793	2025-12-26	EQ.AAPL	273.1444	-0.40960693359375	-0.14973530252399145	yfinance_direct
4794	2025-12-29	EQ.AAPL	273.5041	0.35968017578125	0.1316813244911175	yfinance_direct
4795	2025-12-30	EQ.AAPL	272.8247	-0.67938232421875	-0.2483993295382754	yfinance_direct
4796	2025-12-31	EQ.AAPL	271.6058	-1.2188720703125	-0.44676014997897073	yfinance_direct
4797	2026-01-02	EQ.AAPL	270.7567	-0.84918212890625	-0.31265238798289435	yfinance_direct
4798	2026-01-05	EQ.AAPL	267.0102	-3.746490478515625	-1.383711328725809	yfinance_direct
4799	2026-01-06	EQ.AAPL	262.1147	-4.89544677734375	-1.8334308830022301	yfinance_direct
4800	2026-01-07	EQ.AAPL	260.0866	-2.028106689453125	-0.7737477405627563	yfinance_direct
4801	2026-01-08	EQ.AAPL	258.7979	-1.28875732421875	-0.4955108337700196	yfinance_direct
4802	2026-01-09	EQ.AAPL	259.1275	0.329681396484375	0.12738954148727025	yfinance_direct
4803	2026-01-12	EQ.AAPL	260.0067	0.879180908203125	0.33928502238404934	yfinance_direct
4804	2026-01-13	EQ.AAPL	260.8059	0.799224853515625	0.3073862369276635	yfinance_direct
4805	2026-01-14	EQ.AAPL	259.717	-1.088958740234375	-0.4175360214479395	yfinance_direct
4806	2026-01-15	EQ.AAPL	257.9686	-1.748382568359375	-0.673187624656215	yfinance_direct
4807	2026-01-16	EQ.AAPL	255.2911	-2.6774749755859375	-1.0379073276537703	yfinance_direct
4808	2026-01-20	EQ.AAPL	246.4694	-8.821746826171875	-3.4555634923675607	yfinance_direct
4809	2026-01-21	EQ.AAPL	247.4185	0.9491119384765625	0.38508311068107415	yfinance_direct
4810	2026-01-22	EQ.AAPL	248.1178	0.6993560791015625	0.28266120532466044	yfinance_direct
4811	2026-01-23	EQ.AAPL	247.8081	-0.309722900390625	-0.12482895057522604	yfinance_direct
4812	2026-01-26	EQ.AAPL	255.1712	7.3631134033203125	2.9712962519964927	yfinance_direct
4813	2026-01-27	EQ.AAPL	258.0285	2.8572998046875	1.1197578028024084	yfinance_direct
4814	2026-01-28	EQ.AAPL	256.2003	-1.8282470703125	-0.7085445328186762	yfinance_direct
4815	2026-01-29	EQ.AAPL	258.0385	1.8382568359375	0.7175077196164319	yfinance_direct
4816	2026-01-30	EQ.AAPL	259.2374	1.198883056640625	0.4646139446628648	yfinance_direct
4817	2026-02-02	EQ.AAPL	269.7576	10.520172119140625	4.0581224133847345	yfinance_direct
4818	2026-02-03	EQ.AAPL	269.2281	-0.529510498046875	-0.19629122599375048	yfinance_direct
4819	2026-02-04	EQ.AAPL	276.2315	7.00341796875	2.601295433518634	yfinance_direct
4820	2026-02-05	EQ.AAPL	275.6521	-0.579437255859375	-0.20976508564164784	yfinance_direct
4821	2026-02-06	EQ.AAPL	277.86	2.207916259765625	0.800979389358529	yfinance_direct
4822	2026-02-09	EQ.AAPL	274.62	-3.239990234375	-1.166051394653174	yfinance_direct
4823	2026-02-10	EQ.AAPL	273.68	-0.94000244140625	-0.3422920610733849	yfinance_direct
4824	2026-02-11	EQ.AAPL	275.5	1.82000732421875	0.6650129249217156	yfinance_direct
4825	2026-02-12	EQ.AAPL	261.73	-13.769989013671875	-4.998181130189428	yfinance_direct
4826	2026-02-13	EQ.AAPL	255.78	-5.95001220703125	-2.2733396848946215	yfinance_direct
4827	2026-02-17	EQ.AAPL	263.88	8.100006103515625	3.16678635631116	yfinance_direct
4828	2026-02-18	EQ.AAPL	264.35	0.470001220703125	0.17811172199721978	yfinance_direct
4829	2026-02-19	EQ.AAPL	260.58	-3.77001953125	-1.4261469431454128	yfinance_direct
4830	2026-02-20	EQ.AAPL	264.58	4	1.5350373037534468	yfinance_direct
4831	2026-02-23	EQ.AAPL	266.18	1.600006103515625	0.6047343656806068	yfinance_direct
4832	2026-02-24	EQ.AAPL	272.14	5.96002197265625	2.239094648979052	yfinance_direct
4833	2026-02-25	EQ.AAPL	274.23	2.089996337890625	0.7679856784716407	yfinance_direct
4834	2026-02-26	EQ.AAPL	272.95	-1.279998779296875	-0.4667610137537755	yfinance_direct
4835	2026-02-27	EQ.AAPL	264.18	-8.77001953125	-3.213049693728529	yfinance_direct
4836	2026-03-02	EQ.AAPL	264.72	0.540008544921875	0.20440932693362907	yfinance_direct
4837	2026-03-03	EQ.AAPL	263.75	-0.970001220703125	-0.3664253612232393	yfinance_direct
4838	2026-03-04	EQ.AAPL	262.52	-1.230010986328125	-0.4663548763329384	yfinance_direct
4839	2026-03-05	EQ.AAPL	260.29	-2.22998046875	-0.8494516844711067	yfinance_direct
4840	2026-03-06	EQ.AAPL	257.46	-2.83001708984375	-1.0872553678353483	yfinance_direct
4841	2026-03-09	EQ.AAPL	259.88	2.420013427734375	0.9399570838394211	yfinance_direct
4842	2026-03-10	EQ.AAPL	260.83	0.949981689453125	0.36554627966914943	yfinance_direct
4843	2026-03-11	EQ.AAPL	260.81	-0.019989013671875	-0.00766361795074388	yfinance_direct
4844	2026-03-12	EQ.AAPL	255.76	-5.0500030517578125	-1.9362766377938696	yfinance_direct
4845	2026-03-13	EQ.AAPL	250.12	-5.6399993896484375	-2.2051921765652414	yfinance_direct
4846	2026-03-16	EQ.AAPL	252.82	2.70001220703125	1.0794867502561027	yfinance_direct
4847	2026-03-17	EQ.AAPL	254.23	1.4099884033203125	0.5577044389181313	yfinance_direct
4848	2026-03-18	EQ.AAPL	249.94	-4.2899932861328125	-1.6874457610149367	yfinance_direct
5616	2025-03-26	EQ.LVMH	580.5766	-3.71099853515625	-0.635132176353248	yfinance_direct
5617	2025-03-27	EQ.LVMH	575.303	-5.2735595703125	-0.908331403348995	yfinance_direct
5618	2025-03-28	EQ.LVMH	573.3499	-1.95318603515625	-0.33950559981073153	yfinance_direct
5619	2025-03-31	EQ.LVMH	558.3106	-15.03924560546875	-2.623048652276127	yfinance_direct
5620	2025-04-01	EQ.LVMH	561.6309	3.3203125	0.5947070417358624	yfinance_direct
5621	2025-04-02	EQ.LVMH	561.7286	0.09771728515625	0.01739884354744706	yfinance_direct
5622	2025-04-03	EQ.LVMH	530.1851	-31.54351806640625	-5.615437054415549	yfinance_direct
5623	2025-04-04	EQ.LVMH	517.5872	-12.59796142578125	-2.376143908866958	yfinance_direct
5624	2025-04-07	EQ.LVMH	495.7118	-21.875335693359375	-4.226406190080644	yfinance_direct
5625	2025-04-08	EQ.LVMH	507.6261	11.91424560546875	2.403462064944807	yfinance_direct
5626	2025-04-09	EQ.LVMH	486.7273	-20.898773193359375	-4.11696217078734	yfinance_direct
5627	2025-04-10	EQ.LVMH	511.923	25.19573974609375	5.176561908273079	yfinance_direct
5628	2025-04-11	EQ.LVMH	512.1183	0.1953125	0.038152707882480597	yfinance_direct
5629	2025-04-14	EQ.LVMH	517.6848	5.56646728515625	1.0869493967437402	yfinance_direct
5630	2025-04-15	EQ.LVMH	477.2056	-40.47918701171875	-7.819272631066143	yfinance_direct
5631	2025-04-16	EQ.LVMH	473.8364	-3.36920166015625	-0.7060272273444508	yfinance_direct
5632	2025-04-17	EQ.LVMH	474.2271	0.390655517578125	0.08244522715492413	yfinance_direct
5633	2025-04-22	EQ.LVMH	475.8872	1.66015625	0.3500762220185974	yfinance_direct
5634	2025-04-23	EQ.LVMH	488.5828	12.695526123046875	2.667759318034718	yfinance_direct
5635	2025-04-24	EQ.LVMH	495.4237	6.840972900390625	1.4001666470954186	yfinance_direct
5636	2025-04-25	EQ.LVMH	494.5314	-0.892303466796875	-0.18010914716572488	yfinance_direct
5637	2025-04-28	EQ.LVMH	497.704	3.172607421875	0.6415380721003386	yfinance_direct
5638	2025-04-29	EQ.LVMH	485.1127	-12.591339111328125	-2.5298848484305925	yfinance_direct
5639	2025-04-30	EQ.LVMH	483.7247	-1.38800048828125	-0.2861191810129394	yfinance_direct
5640	2025-05-02	EQ.LVMH	491.6067	7.881988525390625	1.629436849156923	yfinance_direct
5641	2025-05-05	EQ.LVMH	488.0375	-3.5692138671875	-0.7260303701639981	yfinance_direct
5642	2025-05-06	EQ.LVMH	484.9145	-3.123016357421875	-0.6399132266784192	yfinance_direct
5643	2025-05-07	EQ.LVMH	479.3624	-5.552093505859375	-1.1449634879299309	yfinance_direct
5644	2025-05-08	EQ.LVMH	483.1298	3.7674560546875	0.7859307121467332	yfinance_direct
5645	2025-05-09	EQ.LVMH	491.5075	8.377716064453125	1.7340507016588385	yfinance_direct
5646	2025-05-12	EQ.LVMH	525.9601	34.452606201171875	7.009578398828391	yfinance_direct
5647	2025-05-13	EQ.LVMH	532.3054	6.34527587890625	1.2064176251324221	yfinance_direct
5648	2025-05-14	EQ.LVMH	520.7055	-11.59991455078125	-2.1791840016364548	yfinance_direct
5649	2025-05-15	EQ.LVMH	502.9587	-17.746826171875	-3.408227105113337	yfinance_direct
5650	2025-05-16	EQ.LVMH	499.5878	-3.37091064453125	-0.6702162193320167	yfinance_direct
5651	2025-05-19	EQ.LVMH	494.3332	-5.254608154296875	-1.0517887916868962	yfinance_direct
5652	2025-05-20	EQ.LVMH	500.5792	6.246063232421875	1.2635331255873683	yfinance_direct
5653	2025-05-21	EQ.LVMH	489.4255	-11.153717041015625	-2.228162199795403	yfinance_direct
5654	2025-05-22	EQ.LVMH	480.9487	-8.476837158203125	-1.7319974222907006	yfinance_direct
5655	2025-05-23	EQ.LVMH	474.9009	-6.04779052734375	-1.2574711007031467	yfinance_direct
5656	2025-05-26	EQ.LVMH	479.3128	4.41192626953125	0.929020447317851	yfinance_direct
5657	2025-05-27	EQ.LVMH	477.7761	-1.5367431640625	-0.32061383452898173	yfinance_direct
5658	2025-05-28	EQ.LVMH	479.5111	1.735015869140625	0.36314416043264824	yfinance_direct
5659	2025-05-29	EQ.LVMH	477.1316	-2.37945556640625	-0.49622535873873097	yfinance_direct
5660	2025-05-30	EQ.LVMH	474.1573	-2.974334716796875	-0.6233782414942606	yfinance_direct
5661	2025-06-02	EQ.LVMH	473.1163	-1.040985107421875	-0.2195442598164172	yfinance_direct
5662	2025-06-03	EQ.LVMH	469.5471	-3.5692138671875	-0.7544051744573254	yfinance_direct
5663	2025-06-04	EQ.LVMH	472.571	3.023895263671875	0.6440025584099538	yfinance_direct
5664	2025-06-05	EQ.LVMH	466.0771	-6.493927001953125	-1.3741696429482437	yfinance_direct
5665	2025-06-06	EQ.LVMH	467.2172	1.14013671875	0.2446240813419595	yfinance_direct
5666	2025-06-09	EQ.LVMH	467.5146	0.29742431640625	0.06365868390079983	yfinance_direct
5667	2025-06-10	EQ.LVMH	470.7864	3.27178955078125	0.6998261498941318	yfinance_direct
5668	2025-06-11	EQ.LVMH	466.5728	-4.213653564453125	-0.8950244734317949	yfinance_direct
5669	2025-06-12	EQ.LVMH	464.8377	-1.735015869140625	-0.371863949322949	yfinance_direct
5670	2025-06-13	EQ.LVMH	457.4515	-7.386260986328125	-1.5889977043426835	yfinance_direct
5671	2025-06-16	EQ.LVMH	463.3506	5.89910888671875	1.2895594795650633	yfinance_direct
5672	2025-06-17	EQ.LVMH	456.7575	-6.593109130859375	-1.4229202100866016	yfinance_direct
5673	2025-06-18	EQ.LVMH	460.0788	3.321319580078125	0.7271516611613433	yfinance_direct
5674	2025-06-19	EQ.LVMH	448.6772	-11.401580810546875	-2.4781800204857274	yfinance_direct
5675	2025-06-20	EQ.LVMH	446.0995	-2.577728271484375	-0.574517310439793	yfinance_direct
5676	2025-06-23	EQ.LVMH	445.9507	-0.14874267578125	-0.03334293806969974	yfinance_direct
5677	2025-06-24	EQ.LVMH	449.6686	3.7178955078125	0.8337009305604618	yfinance_direct
5678	2025-06-25	EQ.LVMH	440.9935	-8.67510986328125	-1.9292227851699066	yfinance_direct
5679	2025-06-26	EQ.LVMH	433.8056	-7.187957763671875	-1.629946307651042	yfinance_direct
5680	2025-06-27	EQ.LVMH	445.455	11.649444580078125	2.685406854660881	yfinance_direct
5681	2025-06-30	EQ.LVMH	440.7953	-4.659759521484375	-1.046067356458699	yfinance_direct
5682	2025-07-01	EQ.LVMH	465.036	24.240753173828125	5.499322589710218	yfinance_direct
5683	2025-07-02	EQ.LVMH	484.3196	19.2835693359375	4.146683028946798	yfinance_direct
5684	2025-07-03	EQ.LVMH	481.7418	-2.5777587890625	-0.5322433564727416	yfinance_direct
5685	2025-07-04	EQ.LVMH	473.265	-8.476837158203125	-1.7596224333441701	yfinance_direct
5686	2025-07-07	EQ.LVMH	471.2821	-1.982879638671875	-0.4189787339355751	yfinance_direct
5687	2025-07-08	EQ.LVMH	478.5196	7.237518310546875	1.5357082820586607	yfinance_direct
5688	2025-07-09	EQ.LVMH	483.6751	5.155517578125	1.0773889580386797	yfinance_direct
5689	2025-07-10	EQ.LVMH	500.6784	17.00323486328125	3.5154245988107693	yfinance_direct
5690	2025-07-11	EQ.LVMH	483.5264	-17.151947021484375	-3.4257415278062986	yfinance_direct
5691	2025-07-14	EQ.LVMH	475.4462	-8.08026123046875	-1.6711105658009489	yfinance_direct
5692	2025-07-15	EQ.LVMH	473.265	-2.181182861328125	-0.4587654739393379	yfinance_direct
5693	2025-07-16	EQ.LVMH	471.53	-1.735015869140625	-0.366605586155279	yfinance_direct
5694	2025-07-17	EQ.LVMH	472.7693	1.23931884765625	0.2628292857450741	yfinance_direct
5695	2025-07-18	EQ.LVMH	468.7043	-4.06494140625	-0.8598150339045982	yfinance_direct
5696	2025-07-21	EQ.LVMH	464.7881	-3.91619873046875	-0.8355371069994838	yfinance_direct
5697	2025-07-22	EQ.LVMH	461.5659	-3.222198486328125	-0.693261759645882	yfinance_direct
4850	2024-03-20	EQ.SHEL	2589.4558	-2.497802734375	-0.09636757083831216	yfinance_direct
4851	2024-03-21	EQ.SHEL	2619.4319	29.97607421875	1.1576206126653021	yfinance_direct
4852	2024-03-22	EQ.SHEL	2629.9233	10.491455078125	0.4005240655098664	yfinance_direct
4853	2024-03-25	EQ.SHEL	2648.4087	18.4853515625	0.7028855663754161	yfinance_direct
4854	2024-03-26	EQ.SHEL	2644.9119	-3.496826171875	-0.13203499079359454	yfinance_direct
4855	2024-03-27	EQ.SHEL	2610.9387	-33.97314453125	-1.2844717050047911	yfinance_direct
4856	2024-03-28	EQ.SHEL	2622.929	11.990234375	0.4592307846953617	yfinance_direct
4857	2024-04-02	EQ.SHEL	2714.8567	91.927734375	3.5047740884107133	yfinance_direct
4858	2024-04-03	EQ.SHEL	2745.3325	30.475830078125	1.1225575993207946	yfinance_direct
4859	2024-04-04	EQ.SHEL	2761.8196	16.487060546875	0.6005487652071405	yfinance_direct
4860	2024-04-05	EQ.SHEL	2777.8071	15.987548828125	0.5788773800956525	yfinance_direct
4861	2024-04-08	EQ.SHEL	2811.78	33.972900390625	1.2230114912262353	yfinance_direct
4862	2024-04-09	EQ.SHEL	2826.2686	14.488525390625	0.5152794756227094	yfinance_direct
4863	2024-04-10	EQ.SHEL	2866.7366	40.468017578125	1.431853229623451	yfinance_direct
4864	2024-04-11	EQ.SHEL	2854.7461	-11.990478515625	-0.4182623067507296	yfinance_direct
4865	2024-04-12	EQ.SHEL	2934.6829	79.936767578125	2.800135807283649	yfinance_direct
4866	2024-04-15	EQ.SHEL	2887.2205	-47.46240234375	-1.617292381714811	yfinance_direct
4867	2024-04-16	EQ.SHEL	2832.2637	-54.956787109375	-1.9034496288069014	yfinance_direct
4868	2024-04-17	EQ.SHEL	2843.7549	11.4912109375	0.40572532323209337	yfinance_direct
4869	2024-04-18	EQ.SHEL	2839.2581	-4.496826171875	-0.15812987958468477	yfinance_direct
4870	2024-04-19	EQ.SHEL	2848.751	9.492919921875	0.33434509060113066	yfinance_direct
4871	2024-04-22	EQ.SHEL	2904.7065	55.95556640625	1.9642140315742815	yfinance_direct
4872	2024-04-23	EQ.SHEL	2892.7158	-11.99072265625	-0.4128032377410113	yfinance_direct
4873	2024-04-24	EQ.SHEL	2904.7065	11.99072265625	0.41451436646668743	yfinance_direct
4874	2024-04-25	EQ.SHEL	2898.7114	-5.9951171875	-0.2063932138691264	yfinance_direct
4875	2024-04-26	EQ.SHEL	2901.2095	2.498046875	0.08617783932482122	yfinance_direct
4876	2024-04-29	EQ.SHEL	2885.2222	-15.9873046875	-0.5510565451471025	yfinance_direct
4877	2024-04-30	EQ.SHEL	2860.7417	-24.48046875	-0.8484777713750448	yfinance_direct
4878	2024-05-01	EQ.SHEL	2816.7761	-43.965576171875	-1.5368593460878244	yfinance_direct
4879	2024-05-02	EQ.SHEL	2870.7336	53.95751953125	1.915577141178148	yfinance_direct
4880	2024-05-03	EQ.SHEL	2856.2449	-14.48876953125	-0.5047061599988094	yfinance_direct
4881	2024-05-07	EQ.SHEL	2892.7158	36.470947265625	1.2768844719787602	yfinance_direct
4882	2024-05-08	EQ.SHEL	2889.219	-3.496826171875	-0.12088384719025867	yfinance_direct
4883	2024-05-09	EQ.SHEL	2906.2056	16.986572265625	0.587929551206537	yfinance_direct
4884	2024-05-10	EQ.SHEL	2943.676	37.470458984375	1.2893258280662556	yfinance_direct
4885	2024-05-13	EQ.SHEL	2934.6829	-8.9931640625	-0.305507942617653	yfinance_direct
4886	2024-05-14	EQ.SHEL	2898.7114	-35.971435546875	-1.225735019646917	yfinance_direct
4887	2024-05-15	EQ.SHEL	2866.7366	-31.974853515625	-1.103071289926946	yfinance_direct
4888	2024-05-16	EQ.SHEL	2827.0337	-39.702880859375	-1.3849504430746218	yfinance_direct
4889	2024-05-17	EQ.SHEL	2802.5508	-24.48291015625	-0.8660282412153171	yfinance_direct
4890	2024-05-20	EQ.SHEL	2802.0513	-0.49951171875	-0.017823467181822362	yfinance_direct
4891	2024-05-21	EQ.SHEL	2801.5515	-0.499755859375	-0.01783535743293531	yfinance_direct
4892	2024-05-22	EQ.SHEL	2758.5811	-42.970458984375	-1.5338093472375753	yfinance_direct
4893	2024-05-23	EQ.SHEL	2770.573	11.991943359375	0.43471419260992067	yfinance_direct
4894	2024-05-24	EQ.SHEL	2770.0732	-0.499755859375	-0.018037996462367336	yfinance_direct
4895	2024-05-28	EQ.SHEL	2778.5674	8.494140625	0.3066395680676031	yfinance_direct
4896	2024-05-29	EQ.SHEL	2799.553	20.985595703125	0.7552667548369161	yfinance_direct
4897	2024-05-30	EQ.SHEL	2795.0559	-4.4970703125	-0.1606352995285851	yfinance_direct
4898	2024-05-31	EQ.SHEL	2809.5459	14.489990234375	0.5184150410676497	yfinance_direct
4899	2024-06-03	EQ.SHEL	2780.5659	-28.97998046875	-1.031482720565872	yfinance_direct
4900	2024-06-04	EQ.SHEL	2721.1072	-59.458740234375	-2.138368303018351	yfinance_direct
4901	2024-06-05	EQ.SHEL	2715.6116	-5.49560546875	-0.20196210989843127	yfinance_direct
4902	2024-06-06	EQ.SHEL	2734.5974	18.98583984375	0.6991367998888803	yfinance_direct
4903	2024-06-07	EQ.SHEL	2730.6008	-3.99658203125	-0.14614882664454704	yfinance_direct
4904	2024-06-10	EQ.SHEL	2755.583	24.982177734375	0.9148967311220013	yfinance_direct
4905	2024-06-11	EQ.SHEL	2748.5881	-6.994873046875	-0.2538436703609894	yfinance_direct
4906	2024-06-12	EQ.SHEL	2742.5923	-5.995849609375	-0.2181428906548879	yfinance_direct
4907	2024-06-13	EQ.SHEL	2722.1064	-20.48583984375	-0.7469517053127307	yfinance_direct
4908	2024-06-14	EQ.SHEL	2709.1155	-12.990966796875	-0.4772394855919614	yfinance_direct
4909	2024-06-17	EQ.SHEL	2724.1052	14.98974609375	0.553307757185868	yfinance_direct
4910	2024-06-18	EQ.SHEL	2731.6001	7.494873046875	0.275131554360193	yfinance_direct
4911	2024-06-19	EQ.SHEL	2746.0898	14.48974609375	0.5304490253233772	yfinance_direct
4912	2024-06-20	EQ.SHEL	2765.5767	19.48681640625	0.7096204973264543	yfinance_direct
4913	2024-06-21	EQ.SHEL	2775.0696	9.492919921875	0.34325282168597226	yfinance_direct
4914	2024-06-24	EQ.SHEL	2792.5576	17.488037109375	0.6301837343077599	yfinance_direct
4915	2024-06-25	EQ.SHEL	2805.5483	12.99072265625	0.4651908550174694	yfinance_direct
4916	2024-06-26	EQ.SHEL	2789.0601	-16.48828125	-0.5877026253954436	yfinance_direct
4917	2024-06-27	EQ.SHEL	2811.5442	22.484130859375	0.8061544171519758	yfinance_direct
4918	2024-06-28	EQ.SHEL	2832.0295	20.4853515625	0.7286156710375097	yfinance_direct
4919	2024-07-01	EQ.SHEL	2855.5137	23.484130859375	0.8292332590200701	yfinance_direct
4920	2024-07-02	EQ.SHEL	2867.5054	11.99169921875	0.41994893377190373	yfinance_direct
4921	2024-07-03	EQ.SHEL	2849.0186	-18.48681640625	-0.644700323584698	yfinance_direct
4922	2024-07-04	EQ.SHEL	2897.9844	48.9658203125	1.718690818349932	yfinance_direct
4923	2024-07-05	EQ.SHEL	2860.0105	-37.973876953125	-1.3103547859234057	yfinance_direct
4924	2024-07-08	EQ.SHEL	2833.0295	-26.98095703125	-0.9433866431495801	yfinance_direct
4925	2024-07-09	EQ.SHEL	2832.0295	-1	-0.03529790231701946	yfinance_direct
4926	2024-07-10	EQ.SHEL	2831.0312	-0.998291015625	-0.03525002127156456	yfinance_direct
4927	2024-07-11	EQ.SHEL	2813.0435	-17.98779296875	-0.6353795271157816	yfinance_direct
4928	2024-07-12	EQ.SHEL	2810.5452	-2.498291015625	-0.08881096413141003	yfinance_direct
4929	2024-07-15	EQ.SHEL	2805.5483	-4.996826171875	-0.17778850282483669	yfinance_direct
4930	2024-07-16	EQ.SHEL	2780.5659	-24.982421875	-0.8904648521005827	yfinance_direct
4931	2024-07-17	EQ.SHEL	2796.5549	15.989013671875	0.5750273197463069	yfinance_direct
4932	2024-07-18	EQ.SHEL	2832.5295	35.974609375	1.286390228490708	yfinance_direct
4933	2024-07-19	EQ.SHEL	2791.5583	-40.97119140625	-1.446452395746576	yfinance_direct
4934	2024-07-22	EQ.SHEL	2791.0583	-0.5	-0.017911142716037637	yfinance_direct
4935	2024-07-23	EQ.SHEL	2745.0906	-45.9677734375	-1.6469656911305155	yfinance_direct
4936	2024-07-24	EQ.SHEL	2762.0789	16.98828125	0.6188604994481003	yfinance_direct
4937	2024-07-25	EQ.SHEL	2760.0801	-1.998779296875	-0.07236503373189936	yfinance_direct
4938	2024-07-26	EQ.SHEL	2777.5679	17.48779296875	0.6335973041995923	yfinance_direct
4939	2024-07-29	EQ.SHEL	2769.5735	-7.994384765625	-0.28781960105540005	yfinance_direct
4940	2024-07-30	EQ.SHEL	2764.5771	-4.996337890625	-0.18040098648001932	yfinance_direct
4941	2024-07-31	EQ.SHEL	2838.0261	73.448974609375	2.6567887479966807	yfinance_direct
4942	2024-08-01	EQ.SHEL	2823.0364	-14.98974609375	-0.5281750570236882	yfinance_direct
4943	2024-08-02	EQ.SHEL	2775.0696	-47.966796875	-1.699120750500923	yfinance_direct
4944	2024-08-05	EQ.SHEL	2691.6279	-83.441650390625	-3.0068309273987976	yfinance_direct
4945	2024-08-06	EQ.SHEL	2706.6174	14.989501953125	0.556893535982341	yfinance_direct
4946	2024-08-07	EQ.SHEL	2768.574	61.95654296875	2.2890764776902675	yfinance_direct
4947	2024-08-08	EQ.SHEL	2773.0713	4.497314453125	0.1624415491285378	yfinance_direct
4948	2024-08-09	EQ.SHEL	2774.0703	0.9990234375	0.036025883699432146	yfinance_direct
4949	2024-08-12	EQ.SHEL	2797.0549	22.984619140625	0.8285521472565415	yfinance_direct
4950	2024-08-13	EQ.SHEL	2779.0669	-17.988037109375	-0.6431063225070105	yfinance_direct
4951	2024-08-14	EQ.SHEL	2805.0491	25.982177734375	0.9349245167686926	yfinance_direct
4952	2024-08-15	EQ.SHEL	2803.811	-1.238037109375	-0.04413602320244056	yfinance_direct
4953	2024-08-16	EQ.SHEL	2788.3203	-15.49072265625	-0.5524881121450732	yfinance_direct
4954	2024-08-19	EQ.SHEL	2811.3066	22.986328125	0.8243790364382679	yfinance_direct
4955	2024-08-20	EQ.SHEL	2731.3552	-79.951416015625	-2.84392370651714	yfinance_direct
4956	2024-08-21	EQ.SHEL	2716.8635	-14.49169921875	-0.5305680889904216	yfinance_direct
4957	2024-08-22	EQ.SHEL	2706.3699	-10.49365234375	-0.38624142308514536	yfinance_direct
4958	2024-08-23	EQ.SHEL	2718.3628	11.992919921875	0.443136765647379	yfinance_direct
4959	2024-08-27	EQ.SHEL	2723.3596	4.996826171875	0.1838174869373458	yfinance_direct
4960	2024-08-28	EQ.SHEL	2694.3772	-28.982421875	-1.06421574555569	yfinance_direct
4961	2024-08-29	EQ.SHEL	2709.3679	14.99072265625	0.5563706028785895	yfinance_direct
4962	2024-08-30	EQ.SHEL	2679.3862	-29.981689453125	-1.1065935059122398	yfinance_direct
4963	2024-09-02	EQ.SHEL	2682.884	3.497802734375	0.13054492460249267	yfinance_direct
4964	2024-09-03	EQ.SHEL	2610.4277	-72.456298828125	-2.7006869447733313	yfinance_direct
4965	2024-09-04	EQ.SHEL	2580.9456	-29.482177734375	-1.129400264414282	yfinance_direct
4966	2024-09-05	EQ.SHEL	2572.95	-7.99560546875	-0.3097936509422977	yfinance_direct
4967	2024-09-06	EQ.SHEL	2514.4854	-58.464599609375	-2.272278929590011	yfinance_direct
4968	2024-09-09	EQ.SHEL	2544.467	29.981689453125	1.192358883080961	yfinance_direct
4969	2024-09-10	EQ.SHEL	2506.9897	-37.477294921875	-1.4728937069240213	yfinance_direct
4970	2024-09-11	EQ.SHEL	2508.4893	1.49951171875	0.059813237014090484	yfinance_direct
4971	2024-09-12	EQ.SHEL	2535.4729	26.983642578125	1.0756929691481232	yfinance_direct
4972	2024-09-13	EQ.SHEL	2552.9624	17.489501953125	0.6897925018417865	yfinance_direct
4973	2024-09-16	EQ.SHEL	2536.9719	-15.990478515625	-0.6263499415794342	yfinance_direct
4974	2024-09-17	EQ.SHEL	2559.4585	22.486572265625	0.8863547938557488	yfinance_direct
4975	2024-09-18	EQ.SHEL	2552.4624	-6.99609375	-0.27334273092052286	yfinance_direct
4976	2024-09-19	EQ.SHEL	2593.4377	40.975341796875	1.6053259691210406	yfinance_direct
4977	2024-09-20	EQ.SHEL	2560.4578	-32.97998046875	-1.2716704128819725	yfinance_direct
4978	2024-09-23	EQ.SHEL	2575.4485	14.99072265625	0.5854704134916976	yfinance_direct
4979	2024-09-24	EQ.SHEL	2570.4517	-4.996826171875	-0.19401770986299507	yfinance_direct
4980	2024-09-25	EQ.SHEL	2530.4758	-39.975830078125	-1.555206452538189	yfinance_direct
4981	2024-09-26	EQ.SHEL	2413.5464	-116.929443359375	-4.620848062230452	yfinance_direct
4982	2024-09-27	EQ.SHEL	2422.5408	8.994384765625	0.37266260201665286	yfinance_direct
4983	2024-09-30	EQ.SHEL	2423.54	0.999267578125	0.04124874139941571	yfinance_direct
4984	2024-10-01	EQ.SHEL	2476.5085	52.968505859375	2.1855841044765594	yfinance_direct
4985	2024-10-02	EQ.SHEL	2519.4824	42.973876953125	1.735260596667179	yfinance_direct
4986	2024-10-03	EQ.SHEL	2562.4568	42.974365234375	1.705682280664354	yfinance_direct
4987	2024-10-04	EQ.SHEL	2575.9482	13.491455078125	0.5265046866739274	yfinance_direct
4988	2024-10-07	EQ.SHEL	2636.4124	60.464111328125	2.3472564525123674	yfinance_direct
4989	2024-10-08	EQ.SHEL	2574.4495	-61.962890625	-2.350273110440148	yfinance_direct
4990	2024-10-09	EQ.SHEL	2584.4434	9.993896484375	0.38819548134200793	yfinance_direct
4991	2024-10-10	EQ.SHEL	2591.4392	6.995849609375	0.27069076921332946	yfinance_direct
4992	2024-10-11	EQ.SHEL	2590.4397	-0.99951171875	-0.03856975364441306	yfinance_direct
4993	2024-10-14	EQ.SHEL	2587.9412	-2.49853515625	-0.09645216442935783	yfinance_direct
4994	2024-10-15	EQ.SHEL	2500.9937	-86.947509765625	-3.3597174092921014	yfinance_direct
4995	2024-10-16	EQ.SHEL	2530.9756	29.98193359375	1.1988008672334336	yfinance_direct
4996	2024-10-17	EQ.SHEL	2552.9624	21.98681640625	0.8687091463233475	yfinance_direct
4997	2024-10-18	EQ.SHEL	2534.9729	-17.989501953125	-0.7046520519303268	yfinance_direct
4998	2024-10-21	EQ.SHEL	2549.4641	14.4912109375	0.5716515129320312	yfinance_direct
4999	2024-10-22	EQ.SHEL	2562.4568	12.99267578125	0.5096237959781108	yfinance_direct
5000	2024-10-23	EQ.SHEL	2537.9714	-24.4853515625	-0.9555420284812348	yfinance_direct
5001	2024-10-24	EQ.SHEL	2540.47	2.49853515625	0.09844614960024649	yfinance_direct
5002	2024-10-25	EQ.SHEL	2548.9648	8.494873046875	0.33438195077440247	yfinance_direct
5003	2024-10-28	EQ.SHEL	2514.4854	-34.4794921875	-1.3526860628165538	yfinance_direct
5004	2024-10-29	EQ.SHEL	2480.5059	-33.9794921875	-1.3513497768593148	yfinance_direct
5005	2024-10-30	EQ.SHEL	2489.0007	8.494873046875	0.3424653489435985	yfinance_direct
5006	2024-10-31	EQ.SHEL	2576.948	87.947265625	3.5334367113433744	yfinance_direct
5007	2024-11-01	EQ.SHEL	2577.4478	0.499755859375	0.019393323410242497	yfinance_direct
5008	2024-11-04	EQ.SHEL	2592.4385	14.99072265625	0.5816111164050102	yfinance_direct
5009	2024-11-05	EQ.SHEL	2606.9297	14.4912109375	0.5589799360143326	yfinance_direct
5010	2024-11-06	EQ.SHEL	2590.9392	-15.990478515625	-0.6133835750268964	yfinance_direct
5011	2024-11-07	EQ.SHEL	2597.9351	6.995849609375	0.27001210931989833	yfinance_direct
5012	2024-11-08	EQ.SHEL	2562.9563	-34.978759765625	-1.3464062409842854	yfinance_direct
5013	2024-11-11	EQ.SHEL	2548.4651	-14.4912109375	-0.5654099893988008	yfinance_direct
5014	2024-11-12	EQ.SHEL	2516.4841	-31.98095703125	-1.2549105413769184	yfinance_direct
5015	2024-11-13	EQ.SHEL	2523.48	6.995849609375	0.2780009428068966	yfinance_direct
5016	2024-11-14	EQ.SHEL	2530.2468	6.766845703125	0.2681553154968173	yfinance_direct
5017	2024-11-15	EQ.SHEL	2559.7324	29.485595703125	1.1653248765352704	yfinance_direct
5018	2024-11-18	EQ.SHEL	2587.7185	27.986083984375	1.0933206824748987	yfinance_direct
5019	2024-11-19	EQ.SHEL	2571.2266	-16.491943359375	-0.6373159724302419	yfinance_direct
5020	2024-11-20	EQ.SHEL	2549.7371	-21.489501953125	-0.835768510894302	yfinance_direct
5021	2024-11-21	EQ.SHEL	2595.7144	45.977294921875	1.803217109454167	yfinance_direct
5022	2024-11-22	EQ.SHEL	2601.7117	5.997314453125	0.23104678064786402	yfinance_direct
5023	2024-11-25	EQ.SHEL	2572.7261	-28.985595703125	-1.1140971552776018	yfinance_direct
5024	2024-11-26	EQ.SHEL	2553.2358	-19.490234375	-0.7575713003537902	yfinance_direct
5025	2024-11-27	EQ.SHEL	2536.7437	-16.4921875	-0.6459327901730092	yfinance_direct
5026	2024-11-28	EQ.SHEL	2530.2468	-6.496826171875	-0.25610889637478534	yfinance_direct
5027	2024-11-29	EQ.SHEL	2530.2468	0	0	yfinance_direct
5028	2024-12-02	EQ.SHEL	2512.7556	-17.4912109375	-0.6912847693979027	yfinance_direct
5029	2024-12-03	EQ.SHEL	2554.7346	41.97900390625	1.6706361594314634	yfinance_direct
5030	2024-12-04	EQ.SHEL	2529.2473	-25.4873046875	-0.9976497948766809	yfinance_direct
5031	2024-12-05	EQ.SHEL	2492.7656	-36.481689453125	-1.4423931279734534	yfinance_direct
5032	2024-12-06	EQ.SHEL	2476.7734	-15.9921875	-0.6415439678569862	yfinance_direct
5033	2024-12-09	EQ.SHEL	2535.2444	58.470947265625	2.360770928028212	yfinance_direct
5034	2024-12-10	EQ.SHEL	2521.2512	-13.9931640625	-0.5519453724692353	yfinance_direct
5035	2024-12-11	EQ.SHEL	2491.2661	-29.985107421875	-1.1892947111201704	yfinance_direct
5036	2024-12-12	EQ.SHEL	2503.7603	12.494140625	0.5015177045275163	yfinance_direct
5037	2024-12-13	EQ.SHEL	2497.2632	-6.4970703125	-0.25949250941113766	yfinance_direct
5038	2024-12-16	EQ.SHEL	2457.283	-39.980224609375	-1.6009615995635846	yfinance_direct
5039	2024-12-17	EQ.SHEL	2412.3052	-44.977783203125	-1.8303868115259654	yfinance_direct
5040	2024-12-18	EQ.SHEL	2417.8027	5.49755859375	0.22789648046788105	yfinance_direct
5041	2024-12-19	EQ.SHEL	2404.3093	-13.493408203125	-0.5580855713033609	yfinance_direct
5042	2024-12-20	EQ.SHEL	2393.3147	-10.99462890625	-0.45728845230391274	yfinance_direct
5043	2024-12-23	EQ.SHEL	2407.8076	14.492919921875	0.6055584724580199	yfinance_direct
5044	2024-12-24	EQ.SHEL	2427.7981	19.990478515625	0.8302357037550774	yfinance_direct
5045	2024-12-27	EQ.SHEL	2439.292	11.493896484375	0.47342884503936494	yfinance_direct
5046	2024-12-30	EQ.SHEL	2440.7915	1.49951171875	0.06147323582222204	yfinance_direct
5047	2024-12-31	EQ.SHEL	2474.7747	33.983154296875	1.3923005812863678	yfinance_direct
5048	2025-01-02	EQ.SHEL	2525.749	50.974365234375	2.0597578476654625	yfinance_direct
5049	2025-01-03	EQ.SHEL	2565.2297	39.480712890625	1.563128898566986	yfinance_direct
5050	2025-01-06	EQ.SHEL	2576.2241	10.994384765625	0.42859259776718417	yfinance_direct
5051	2025-01-07	EQ.SHEL	2615.7046	39.48046875	1.5324935601192318	yfinance_direct
5052	2025-01-08	EQ.SHEL	2578.2231	-37.4814453125	-1.4329387751978127	yfinance_direct
5053	2025-01-09	EQ.SHEL	2612.2065	33.9833984375	1.3180937619609556	yfinance_direct
5054	2025-01-10	EQ.SHEL	2623.7004	11.493896484375	0.440007185316682	yfinance_direct
5055	2025-01-13	EQ.SHEL	2661.6819	37.9814453125	1.4476288810020064	yfinance_direct
5056	2025-01-14	EQ.SHEL	2671.677	9.9951171875	0.37551884936768554	yfinance_direct
5057	2025-01-15	EQ.SHEL	2680.1726	8.49560546875	0.31798774561967263	yfinance_direct
5058	2025-01-16	EQ.SHEL	2687.6692	7.49658203125	0.2797051954971344	yfinance_direct
5059	2025-01-17	EQ.SHEL	2719.1533	31.484130859375	1.1714287972241573	yfinance_direct
5060	2025-01-20	EQ.SHEL	2721.1523	1.9990234375	0.07351639286269673	yfinance_direct
5061	2025-01-21	EQ.SHEL	2694.1658	-26.986572265625	-0.9917332385894647	yfinance_direct
5062	2025-01-22	EQ.SHEL	2694.6658	0.5	0.0185586204565475	yfinance_direct
5063	2025-01-23	EQ.SHEL	2681.6719	-12.993896484375	-0.4822080950401958	yfinance_direct
5064	2025-01-24	EQ.SHEL	2618.7029	-62.968994140625	-2.348124493815076	yfinance_direct
5065	2025-01-27	EQ.SHEL	2582.2214	-36.4814453125	-1.3931112834201316	yfinance_direct
5066	2025-01-28	EQ.SHEL	2579.7227	-2.498779296875	-0.09676859089142356	yfinance_direct
5067	2025-01-29	EQ.SHEL	2593.7156	13.992919921875	0.5424195460691783	yfinance_direct
5068	2025-01-30	EQ.SHEL	2661.6819	67.96630859375	2.6204225790270748	yfinance_direct
5069	2025-01-31	EQ.SHEL	2677.1743	15.492431640625	0.5820542165199125	yfinance_direct
5070	2025-02-03	EQ.SHEL	2625.6997	-51.474609375	-1.92272161956558	yfinance_direct
5071	2025-02-04	EQ.SHEL	2650.6875	24.98779296875	0.9516622522307577	yfinance_direct
5072	2025-02-05	EQ.SHEL	2643.6912	-6.996337890625	-0.2639442744806772	yfinance_direct
5073	2025-02-06	EQ.SHEL	2645.1899	1.498779296875	0.05669267720663479	yfinance_direct
5074	2025-02-07	EQ.SHEL	2643.6912	-1.498779296875	-0.05666055482118652	yfinance_direct
5075	2025-02-10	EQ.SHEL	2638.1936	-5.49755859375	-0.20795010675012252	yfinance_direct
5076	2025-02-11	EQ.SHEL	2698.1636	59.969970703125	2.273145178701432	yfinance_direct
5077	2025-02-12	EQ.SHEL	2700.1628	1.999267578125	0.07409734521762215	yfinance_direct
5078	2025-02-13	EQ.SHEL	2650.4602	-49.70263671875	-1.8407273794522123	yfinance_direct
5079	2025-02-14	EQ.SHEL	2672.9514	22.4912109375	0.8485775751097175	yfinance_direct
5080	2025-02-17	EQ.SHEL	2685.9463	12.994873046875	0.4861619619800466	yfinance_direct
5081	2025-02-18	EQ.SHEL	2678.949	-6.997314453125	-0.26051579965016114	yfinance_direct
5082	2025-02-19	EQ.SHEL	2684.9468	5.997802734375	0.22388641184364313	yfinance_direct
5083	2025-02-20	EQ.SHEL	2682.9475	-1.999267578125	-0.07446209343869749	yfinance_direct
5084	2025-02-21	EQ.SHEL	2636.4658	-46.481689453125	-1.7324859798388494	yfinance_direct
5085	2025-02-24	EQ.SHEL	2632.467	-3.998779296875	-0.15167195668028896	yfinance_direct
5086	2025-02-25	EQ.SHEL	2628.469	-3.998046875	-0.1518745273049088	yfinance_direct
5087	2025-02-26	EQ.SHEL	2645.9622	17.4931640625	0.6655267420500568	yfinance_direct
5088	2025-02-27	EQ.SHEL	2650.9602	4.998046875	0.18889336189124403	yfinance_direct
5089	2025-02-28	EQ.SHEL	2634.9661	-15.994140625	-0.6033338634945161	yfinance_direct
5090	2025-03-03	EQ.SHEL	2655.4583	20.4921875	0.7777021410806313	yfinance_direct
5091	2025-03-04	EQ.SHEL	2566.9932	-88.465087890625	-3.3314433704825803	yfinance_direct
5092	2025-03-05	EQ.SHEL	2527.5085	-39.484619140625	-1.5381661195441987	yfinance_direct
5093	2025-03-06	EQ.SHEL	2532.0066	4.498046875	0.17796366639540023	yfinance_direct
5094	2025-03-07	EQ.SHEL	2553.4983	21.49169921875	0.8488010769157637	yfinance_direct
5095	2025-03-10	EQ.SHEL	2571.991	18.49267578125	0.7242094442089776	yfinance_direct
5096	2025-03-11	EQ.SHEL	2551.9988	-19.9921875	-0.7773039547218168	yfinance_direct
5097	2025-03-12	EQ.SHEL	2567.4927	15.493896484375	0.6071278955957756	yfinance_direct
5098	2025-03-13	EQ.SHEL	2601.9795	34.48681640625	1.343209923500801	yfinance_direct
5099	2025-03-14	EQ.SHEL	2632.467	30.487548828125	1.171705961544452	yfinance_direct
5100	2025-03-17	EQ.SHEL	2674.9507	42.483642578125	1.613833788465382	yfinance_direct
5101	2025-03-18	EQ.SHEL	2694.9431	19.992431640625	0.7473944010723036	yfinance_direct
5102	2025-03-19	EQ.SHEL	2739.925	44.98193359375	1.6691236760980015	yfinance_direct
5103	2025-03-20	EQ.SHEL	2748.4219	8.496826171875	0.3101116278895702	yfinance_direct
5104	2025-03-21	EQ.SHEL	2725.9307	-22.4912109375	-0.8183318267869629	yfinance_direct
5105	2025-03-24	EQ.SHEL	2723.9314	-1.999267578125	-0.07334256899790173	yfinance_direct
5106	2025-03-25	EQ.SHEL	2763.9158	39.984375	1.467892144846437	yfinance_direct
5107	2025-03-26	EQ.SHEL	2829.8899	65.97412109375	2.3869801596131226	yfinance_direct
5108	2025-03-27	EQ.SHEL	2821.3931	-8.496826171875	-0.3002528894908383	yfinance_direct
5109	2025-03-28	EQ.SHEL	2795.4036	-25.989501953125	-0.921158496580171	yfinance_direct
5110	2025-03-31	EQ.SHEL	2823.8921	28.488525390625	1.0191203070959207	yfinance_direct
5111	2025-04-01	EQ.SHEL	2805.3997	-18.492431640625	-0.6548561719880809	yfinance_direct
5112	2025-04-02	EQ.SHEL	2778.9099	-26.48974609375	-0.9442414386945793	yfinance_direct
5113	2025-04-03	EQ.SHEL	2666.4539	-112.4560546875	-4.046768633897113	yfinance_direct
5114	2025-04-04	EQ.SHEL	2480.5269	-185.927001953125	-6.972819028373999	yfinance_direct
5115	2025-04-07	EQ.SHEL	2369.5708	-110.9560546875	-4.473084193500192	yfinance_direct
5116	2025-04-08	EQ.SHEL	2393.061	23.490234375	0.9913286561116994	yfinance_direct
5117	2025-04-09	EQ.SHEL	2290.6016	-102.45947265625	-4.281523586361855	yfinance_direct
5118	2025-04-10	EQ.SHEL	2325.0879	34.486328125	1.5055576967022173	yfinance_direct
5119	2025-04-11	EQ.SHEL	2307.0947	-17.9931640625	-0.7738702754012156	yfinance_direct
5120	2025-04-14	EQ.SHEL	2353.5767	46.48193359375	2.0147388426918496	yfinance_direct
5121	2025-04-15	EQ.SHEL	2370.5698	16.9931640625	0.7220144705790825	yfinance_direct
5122	2025-04-16	EQ.SHEL	2433.5454	62.9755859375	2.6565589966646255	yfinance_direct
5123	2025-04-17	EQ.SHEL	2438.0437	4.498291015625	0.18484516446053	yfinance_direct
5124	2025-04-22	EQ.SHEL	2431.0464	-6.997314453125	-0.28700529238920763	yfinance_direct
5125	2025-04-23	EQ.SHEL	2430.5466	-0.499755859375	-0.020557232560647853	yfinance_direct
5126	2025-04-24	EQ.SHEL	2433.0457	2.4990234375	0.10281734181814127	yfinance_direct
5127	2025-04-25	EQ.SHEL	2463.0337	29.988037109375	1.232530801730526	yfinance_direct
5128	2025-04-28	EQ.SHEL	2457.0361	-5.99755859375	-0.24350290516431142	yfinance_direct
5129	2025-04-29	EQ.SHEL	2442.0417	-14.994384765625	-0.6102630956615746	yfinance_direct
5130	2025-04-30	EQ.SHEL	2439.5427	-2.4990234375	-0.10233336262570852	yfinance_direct
5131	2025-05-01	EQ.SHEL	2435.5447	-3.998046875	-0.16388509349186234	yfinance_direct
5132	2025-05-02	EQ.SHEL	2485.5249	49.980224609375	2.05211692753131	yfinance_direct
5133	2025-05-06	EQ.SHEL	2433.0457	-52.479248046875	-2.1113949812930533	yfinance_direct
5134	2025-05-07	EQ.SHEL	2428.0476	-4.998046875	-0.20542347268220018	yfinance_direct
5135	2025-05-08	EQ.SHEL	2435.0447	6.9970703125	0.28817681709007176	yfinance_direct
5136	2025-05-09	EQ.SHEL	2457.0361	21.991455078125	0.9031232683002098	yfinance_direct
5137	2025-05-12	EQ.SHEL	2491.0227	33.986572265625	1.383234532522789	yfinance_direct
5138	2025-05-13	EQ.SHEL	2521.5107	30.488037109375	1.223916468012234	yfinance_direct
5139	2025-05-14	EQ.SHEL	2513.5139	-7.996826171875	-0.3171442436504343	yfinance_direct
5140	2025-05-15	EQ.SHEL	2472.29	-41.223876953125	-1.640089465606473	yfinance_direct
5141	2025-05-16	EQ.SHEL	2489.7849	17.494873046875	0.7076383745617933	yfinance_direct
5142	2025-05-19	EQ.SHEL	2472.29	-17.494873046875	-0.7026660400176149	yfinance_direct
5143	2025-05-20	EQ.SHEL	2485.7859	13.495849609375	0.5458845603120526	yfinance_direct
5144	2025-05-21	EQ.SHEL	2476.7886	-8.997314453125	-0.361950500005942	yfinance_direct
5145	2025-05-22	EQ.SHEL	2439.2991	-37.489501953125	-1.5136335149216464	yfinance_direct
5146	2025-05-23	EQ.SHEL	2419.3052	-19.993896484375	-0.8196574463419377	yfinance_direct
5147	2025-05-27	EQ.SHEL	2445.7976	26.492431640625	1.0950429861362974	yfinance_direct
5148	2025-05-28	EQ.SHEL	2444.2976	-1.5	-0.0613296862932643	yfinance_direct
5149	2025-05-29	EQ.SHEL	2440.7991	-3.49853515625	-0.14313049056002974	yfinance_direct
5150	2025-05-30	EQ.SHEL	2448.7969	7.997802734375	0.3276714919000355	yfinance_direct
5151	2025-06-02	EQ.SHEL	2467.7913	18.994384765625	0.7756619162471367	yfinance_direct
5152	2025-06-03	EQ.SHEL	2509.2793	41.488037109375	1.6811809728718816	yfinance_direct
5153	2025-06-04	EQ.SHEL	2479.2878	-29.991455078125	-1.1952218756786335	yfinance_direct
5154	2025-06-05	EQ.SHEL	2478.2881	-0.999755859375	-0.04032431581846594	yfinance_direct
5155	2025-06-06	EQ.SHEL	2506.78	28.491943359375	1.149662281840689	yfinance_direct
5156	2025-06-09	EQ.SHEL	2504.2808	-2.499267578125	-0.09970031470316196	yfinance_direct
5157	2025-06-10	EQ.SHEL	2594.7549	90.47412109375	3.61277866590547	yfinance_direct
5158	2025-06-11	EQ.SHEL	2580.7588	-13.99609375	-0.5393994570627569	yfinance_direct
5159	2025-06-12	EQ.SHEL	2613.749	32.990234375	1.2783152968350135	yfinance_direct
5160	2025-06-13	EQ.SHEL	2630.2444	16.495361328125	0.6310996648955587	yfinance_direct
5161	2025-06-16	EQ.SHEL	2624.7461	-5.498291015625	-0.20904107038384345	yfinance_direct
5162	2025-06-17	EQ.SHEL	2662.2354	37.4892578125	1.428300356433286	yfinance_direct
5163	2025-06-18	EQ.SHEL	2666.2344	3.9990234375	0.15021299432271915	yfinance_direct
5164	2025-06-19	EQ.SHEL	2697.2253	30.990966796875	1.1623496826634006	yfinance_direct
5165	2025-06-20	EQ.SHEL	2682.2295	-14.995849609375	-0.5559731838862546	yfinance_direct
5166	2025-06-23	EQ.SHEL	2683.2292	0.999755859375	0.037273315437287444	yfinance_direct
5167	2025-06-24	EQ.SHEL	2583.7578	-99.471435546875	-3.7071538192005153	yfinance_direct
5168	2025-06-25	EQ.SHEL	2562.7639	-20.993896484375	-0.8125334496448668	yfinance_direct
5169	2025-06-26	EQ.SHEL	2575.7603	12.996337890625	0.5071219322781257	yfinance_direct
5170	2025-06-27	EQ.SHEL	2586.2571	10.496826171875	0.4075234158907498	yfinance_direct
5171	2025-06-30	EQ.SHEL	2552.7666	-33.490478515625	-1.2949400418698256	yfinance_direct
5172	2025-07-01	EQ.SHEL	2573.261	20.494384765625	0.8028303391732239	yfinance_direct
5173	2025-07-02	EQ.SHEL	2614.749	41.488037109375	1.6122747490364635	yfinance_direct
5174	2025-07-03	EQ.SHEL	2619.7476	4.99853515625	0.191166919327448	yfinance_direct
5175	2025-07-04	EQ.SHEL	2627.2454	7.497802734375	0.2862032530493027	yfinance_direct
5176	2025-07-07	EQ.SHEL	2552.2668	-74.978515625	-2.8538832622430386	yfinance_direct
5177	2025-07-08	EQ.SHEL	2603.2522	50.9853515625	1.9976497225725638	yfinance_direct
5178	2025-07-09	EQ.SHEL	2626.2458	22.99365234375	0.8832664145218745	yfinance_direct
5179	2025-07-10	EQ.SHEL	2657.2368	30.990966796875	1.1800481969913275	yfinance_direct
5180	2025-07-11	EQ.SHEL	2671.2329	13.99609375	0.5267160858070926	yfinance_direct
5181	2025-07-14	EQ.SHEL	2635.7429	-35.489990234375	-1.3285996177809543	yfinance_direct
5182	2025-07-15	EQ.SHEL	2620.7473	-14.99560546875	-0.5689327800297943	yfinance_direct
5183	2025-07-16	EQ.SHEL	2607.2512	-13.49609375	-0.5149711944974843	yfinance_direct
5184	2025-07-17	EQ.SHEL	2608.2507	0.99951171875	0.038335842392680945	yfinance_direct
5185	2025-07-18	EQ.SHEL	2619.2476	10.996826171875	0.42161691110363325	yfinance_direct
5186	2025-07-21	EQ.SHEL	2612.2498	-6.997802734375	-0.2671684358897353	yfinance_direct
5187	2025-07-22	EQ.SHEL	2618.248	5.998291015625	0.22962165092256612	yfinance_direct
5188	2025-07-23	EQ.SHEL	2652.738	34.489990234375	1.3172926940799363	yfinance_direct
5189	2025-07-24	EQ.SHEL	2661.7356	8.99755859375	0.3391800648191566	yfinance_direct
5190	2025-07-25	EQ.SHEL	2666.7339	4.998291015625	0.1877831526051576	yfinance_direct
5191	2025-07-28	EQ.SHEL	2686.2285	19.49462890625	0.7310301565274264	yfinance_direct
5192	2025-07-29	EQ.SHEL	2696.2253	9.996826171875	0.37215099585632444	yfinance_direct
5193	2025-07-30	EQ.SHEL	2678.2307	-17.99462890625	-0.6674007779430499	yfinance_direct
5194	2025-07-31	EQ.SHEL	2710.2217	31.990966796875	1.1944813657351805	yfinance_direct
5195	2025-08-01	EQ.SHEL	2706.2224	-3.999267578125	-0.14756237868284386	yfinance_direct
5196	2025-08-04	EQ.SHEL	2681.23	-24.992431640625	-0.9235172810923754	yfinance_direct
5197	2025-08-05	EQ.SHEL	2690.7271	9.4970703125	0.35420573325230614	yfinance_direct
5198	2025-08-06	EQ.SHEL	2725.717	34.989990234375	1.3003916627000753	yfinance_direct
5199	2025-08-07	EQ.SHEL	2650.2388	-75.478271484375	-2.7691161756192844	yfinance_direct
5200	2025-08-08	EQ.SHEL	2652.238	1.999267578125	0.07543726252554264	yfinance_direct
5201	2025-08-11	EQ.SHEL	2643.7407	-8.497314453125	-0.3203827987621377	yfinance_direct
5202	2025-08-12	EQ.SHEL	2675.2317	31.490966796875	1.1911518602034101	yfinance_direct
5203	2025-08-13	EQ.SHEL	2668.7336	-6.498046875	-0.24289660221273549	yfinance_direct
5204	2025-08-14	EQ.SHEL	2627.5073	-41.226318359375	-1.5447895474330062	yfinance_direct
5205	2025-08-15	EQ.SHEL	2638.5054	10.998046875	0.4185734050530232	yfinance_direct
5206	2025-08-18	EQ.SHEL	2632.5063	-5.9990234375	-0.22736445804592778	yfinance_direct
5207	2025-08-19	EQ.SHEL	2652.5027	19.996337890625	0.7595931500194848	yfinance_direct
5208	2025-08-20	EQ.SHEL	2665.5002	12.99755859375	0.4900111379555588	yfinance_direct
5209	2025-08-21	EQ.SHEL	2676.998	11.497802734375	0.43135628142033683	yfinance_direct
5210	2025-08-22	EQ.SHEL	2691.4954	14.497314453125	0.5415511778220561	yfinance_direct
5211	2025-08-26	EQ.SHEL	2706.4924	14.9970703125	0.5572021608500807	yfinance_direct
5212	2025-08-27	EQ.SHEL	2714.991	8.49853515625	0.31400550235783764	yfinance_direct
5213	2025-08-28	EQ.SHEL	2714.991	0	0	yfinance_direct
5214	2025-08-29	EQ.SHEL	2723.4895	8.49853515625	0.3130225941884626	yfinance_direct
5215	2025-09-01	EQ.SHEL	2716.4907	-6.998779296875	-0.25697838349866564	yfinance_direct
5216	2025-09-02	EQ.SHEL	2729.988	13.497314453125	0.49686584020161867	yfinance_direct
5217	2025-09-03	EQ.SHEL	2693.4949	-36.4931640625	-1.3367517940166684	yfinance_direct
5218	2025-09-04	EQ.SHEL	2687.4961	-5.998779296875	-0.22271359626124682	yfinance_direct
5219	2025-09-05	EQ.SHEL	2627.0073	-60.48876953125	-2.250748184227012	yfinance_direct
5220	2025-09-08	EQ.SHEL	2638.5054	11.498046875	0.4376861369588843	yfinance_direct
5221	2025-09-09	EQ.SHEL	2664.0005	25.4951171875	0.9662711877266866	yfinance_direct
5222	2025-09-10	EQ.SHEL	2655.5022	-8.498291015625	-0.3190048595339371	yfinance_direct
5223	2025-09-11	EQ.SHEL	2644.5042	-10.998046875	-0.4141607145467515	yfinance_direct
5224	2025-09-12	EQ.SHEL	2636.5059	-7.998291015625	-0.30244955427442066	yfinance_direct
5225	2025-09-15	EQ.SHEL	2626.0078	-10.498046875	-0.3981802975203183	yfinance_direct
5226	2025-09-16	EQ.SHEL	2636.5059	10.498046875	0.3997721113025059	yfinance_direct
5227	2025-09-17	EQ.SHEL	2605.5115	-30.994384765625	-1.1755856583976039	yfinance_direct
5228	2025-09-18	EQ.SHEL	2622.0083	16.496826171875	0.6331511617828606	yfinance_direct
5229	2025-09-19	EQ.SHEL	2612.0103	-9.998046875	-0.3813125561814963	yfinance_direct
5230	2025-09-22	EQ.SHEL	2614.0098	1.99951171875	0.07655068412383677	yfinance_direct
5231	2025-09-23	EQ.SHEL	2644.5042	30.494384765625	1.166575013094257	yfinance_direct
5232	2025-09-24	EQ.SHEL	2672.499	27.994873046875	1.0586057519607153	yfinance_direct
5233	2025-09-25	EQ.SHEL	2698.4939	25.994873046875	0.9726803571826609	yfinance_direct
5234	2025-09-26	EQ.SHEL	2732.9875	34.49365234375	1.2782557110352808	yfinance_direct
5235	2025-09-29	EQ.SHEL	2695.4946	-37.492919921875	-1.3718657422333136	yfinance_direct
5236	2025-09-30	EQ.SHEL	2646.0039	-49.49072265625	-1.8360534695753348	yfinance_direct
5237	2025-10-01	EQ.SHEL	2679.9976	33.99365234375	1.2847166349019823	yfinance_direct
5238	2025-10-02	EQ.SHEL	2669.9995	-9.998046875	-0.3730617904087264	yfinance_direct
5239	2025-10-03	EQ.SHEL	2701.9934	31.993896484375	1.1982734957048615	yfinance_direct
5240	2025-10-06	EQ.SHEL	2736.4871	34.49365234375	1.276600166344925	yfinance_direct
5241	2025-10-07	EQ.SHEL	2778.479	41.991943359375	1.5345200773937917	yfinance_direct
5242	2025-10-08	EQ.SHEL	2763.4819	-14.9970703125	-0.5397582739122985	yfinance_direct
5243	2025-10-09	EQ.SHEL	2775.9795	12.49755859375	0.452239562047639	yfinance_direct
5244	2025-10-10	EQ.SHEL	2695.4946	-80.48486328125	-2.8993320558656976	yfinance_direct
5245	2025-10-13	EQ.SHEL	2696.4944	0.999755859375	0.03708988504943416	yfinance_direct
5246	2025-10-14	EQ.SHEL	2685.4966	-10.997802734375	-0.4078555770970356	yfinance_direct
5247	2025-10-15	EQ.SHEL	2690.9954	5.498779296875	0.20475838002057128	yfinance_direct
5248	2025-10-16	EQ.SHEL	2675.9983	-14.9970703125	-0.557305691716179	yfinance_direct
5249	2025-10-17	EQ.SHEL	2690.4956	14.497314453125	0.5417535019285388	yfinance_direct
5250	2025-10-20	EQ.SHEL	2710.4919	19.996337890625	0.7432213548306893	yfinance_direct
5251	2025-10-21	EQ.SHEL	2716.4907	5.998779296875	0.22131699419257939	yfinance_direct
5252	2025-10-22	EQ.SHEL	2760.4824	43.99169921875	1.6194312335340448	yfinance_direct
5253	2025-10-23	EQ.SHEL	2839.9675	79.485107421875	2.879391905994692	yfinance_direct
5254	2025-10-24	EQ.SHEL	2850.4656	10.498046875	0.3696537642315625	yfinance_direct
5255	2025-10-27	EQ.SHEL	2831.4692	-18.996337890625	-0.6664293036696394	yfinance_direct
5256	2025-10-28	EQ.SHEL	2832.469	0.999755859375	0.035308731094739663	yfinance_direct
5257	2025-10-29	EQ.SHEL	2874.9612	42.4921875	1.5001819115372943	yfinance_direct
5258	2025-10-30	EQ.SHEL	2882.4597	7.49853515625	0.2608221357608344	yfinance_direct
5259	2025-10-31	EQ.SHEL	2846.9663	-35.493408203125	-1.2313583428866421	yfinance_direct
5260	2025-11-03	EQ.SHEL	2840.9673	-5.9990234375	-0.21071634811383486	yfinance_direct
5261	2025-11-04	EQ.SHEL	2837.468	-3.499267578125	-0.12317169565479683	yfinance_direct
5262	2025-11-05	EQ.SHEL	2862.9631	25.4951171875	0.8985164600819341	yfinance_direct
5263	2025-11-06	EQ.SHEL	2849.4658	-13.497314453125	-0.4714456253112023	yfinance_direct
5264	2025-11-07	EQ.SHEL	2848.4661	-0.999755859375	-0.03508572913028861	yfinance_direct
5265	2025-11-10	EQ.SHEL	2868.9622	20.49609375	0.7195484617414613	yfinance_direct
5266	2025-11-11	EQ.SHEL	2930.9504	61.98828125	2.1606517559933316	yfinance_direct
5267	2025-11-12	EQ.SHEL	2908.4548	-22.49560546875	-0.7675191352927608	yfinance_direct
5268	2025-11-13	EQ.SHEL	2859.228	-49.226806640625	-1.692541553866518	yfinance_direct
5269	2025-11-14	EQ.SHEL	2857.728	-1.5	-0.052461712939821534	yfinance_direct
5270	2025-11-17	EQ.SHEL	2857.728	0	0	yfinance_direct
5271	2025-11-18	EQ.SHEL	2817.2319	-40.49609375	-1.417073051127297	yfinance_direct
5272	2025-11-19	EQ.SHEL	2793.7341	-23.497802734375	-0.8340741297930859	yfinance_direct
5273	2025-11-20	EQ.SHEL	2813.2324	19.498291015625	0.697929369879845	yfinance_direct
5274	2025-11-21	EQ.SHEL	2784.7351	-28.497314453125	-1.0129740518962076	yfinance_direct
5275	2025-11-24	EQ.SHEL	2771.7363	-12.998779296875	-0.46678692211085565	yfinance_direct
5276	2025-11-25	EQ.SHEL	2765.7368	-5.99951171875	-0.21645319065426752	yfinance_direct
5277	2025-11-26	EQ.SHEL	2766.2368	0.5	0.01807836512259656	yfinance_direct
5278	2025-11-27	EQ.SHEL	2752.738	-13.498779296875	-0.4879835022372346	yfinance_direct
5279	2025-11-28	EQ.SHEL	2783.2351	30.4970703125	1.1078813131279537	yfinance_direct
5280	2025-12-01	EQ.SHEL	2800.2336	16.99853515625	0.6107473677276165	yfinance_direct
5281	2025-12-02	EQ.SHEL	2788.2346	-11.9990234375	-0.42850079561406573	yfinance_direct
5282	2025-12-03	EQ.SHEL	2798.7336	10.4990234375	0.3765473452422721	yfinance_direct
5283	2025-12-04	EQ.SHEL	2799.2336	0.5	0.017865222770517462	yfinance_direct
5284	2025-12-05	EQ.SHEL	2759.7375	-39.49609375	-1.4109609555000797	yfinance_direct
5285	2025-12-08	EQ.SHEL	2749.7383	-9.999267578125	-0.3623267575705167	yfinance_direct
5286	2025-12-09	EQ.SHEL	2734.24	-15.498291015625	-0.5636278594695802	yfinance_direct
5287	2025-12-10	EQ.SHEL	2708.7422	-25.497802734375	-0.9325371154486467	yfinance_direct
5288	2025-12-11	EQ.SHEL	2706.7424	-1.999755859375	-0.0738259945373631	yfinance_direct
5289	2025-12-12	EQ.SHEL	2686.2444	-20.498046875	-0.7572958045577914	yfinance_direct
5290	2025-12-15	EQ.SHEL	2698.2434	11.9990234375	0.4466839839870681	yfinance_direct
5291	2025-12-16	EQ.SHEL	2626.2502	-71.9931640625	-2.6681493538955148	yfinance_direct
5292	2025-12-17	EQ.SHEL	2657.2473	30.9970703125	1.1802786265953502	yfinance_direct
5293	2025-12-18	EQ.SHEL	2661.7468	4.49951171875	0.16932980585873778	yfinance_direct
5294	2025-12-19	EQ.SHEL	2702.7429	40.99609375	1.540195083427998	yfinance_direct
5295	2025-12-22	EQ.SHEL	2704.7427	1.999755859375	0.07398986580021472	yfinance_direct
5296	2025-12-23	EQ.SHEL	2701.7429	-2.999755859375	-0.11090725510546164	yfinance_direct
5297	2025-12-24	EQ.SHEL	2697.7434	-3.99951171875	-0.1480345035517166	yfinance_direct
5298	2025-12-29	EQ.SHEL	2705.7427	7.999267578125	0.2965169909710961	yfinance_direct
5299	2025-12-30	EQ.SHEL	2731.2402	25.49755859375	0.942349722387695	yfinance_direct
5300	2025-12-31	EQ.SHEL	2739.7393	8.4990234375	0.31117817211875043	yfinance_direct
5301	2026-01-02	EQ.SHEL	2759.2375	19.498291015625	0.7116841852751014	yfinance_direct
5302	2026-01-05	EQ.SHEL	2737.7395	-21.498046875	-0.7791299768347394	yfinance_direct
5303	2026-01-06	EQ.SHEL	2746.7388	8.999267578125	0.32871160940275185	yfinance_direct
5304	2026-01-07	EQ.SHEL	2655.2473	-91.491455078125	-3.3309121381695372	yfinance_direct
5305	2026-01-08	EQ.SHEL	2561.7563	-93.490966796875	-3.520989035107278	yfinance_direct
5306	2026-01-09	EQ.SHEL	2639.7488	77.992431640625	3.0444906172275226	yfinance_direct
5307	2026-01-12	EQ.SHEL	2661.2468	21.498046875	0.8143974549247157	yfinance_direct
5308	2026-01-13	EQ.SHEL	2721.741	60.494140625	2.2731503154864834	yfinance_direct
5309	2026-01-14	EQ.SHEL	2738.7395	16.99853515625	0.6245463974573231	yfinance_direct
5310	2026-01-15	EQ.SHEL	2746.2388	7.499267578125	0.2738218648680138	yfinance_direct
5311	2026-01-16	EQ.SHEL	2752.238	5.999267578125	0.21845396855820381	yfinance_direct
5312	2026-01-19	EQ.SHEL	2729.7402	-22.497802734375	-0.8174366617650568	yfinance_direct
5313	2026-01-20	EQ.SHEL	2721.741	-7.999267578125	-0.2930413479419044	yfinance_direct
5314	2026-01-21	EQ.SHEL	2733.24	11.4990234375	0.4224877965162428	yfinance_direct
5315	2026-01-22	EQ.SHEL	2673.7456	-59.494384765625	-2.1766981669444756	yfinance_direct
5316	2026-01-23	EQ.SHEL	2687.2444	13.498779296875	0.5048640105949216	yfinance_direct
5317	2026-01-26	EQ.SHEL	2672.2458	-14.99853515625	-0.558138115062361	yfinance_direct
5318	2026-01-27	EQ.SHEL	2696.7434	24.49755859375	0.9167404487626397	yfinance_direct
5319	2026-01-28	EQ.SHEL	2732.24	35.49658203125	1.316275843051076	yfinance_direct
5320	2026-01-29	EQ.SHEL	2797.2339	64.993896484375	2.3787770004347144	yfinance_direct
5321	2026-01-30	EQ.SHEL	2793.7341	-3.499755859375	-0.12511488138306276	yfinance_direct
5322	2026-02-02	EQ.SHEL	2779.2356	-14.49853515625	-0.5189661749162271	yfinance_direct
5323	2026-02-03	EQ.SHEL	2789.2346	9.9990234375	0.3597760280905702	yfinance_direct
5324	2026-02-04	EQ.SHEL	2866.7273	77.49267578125	2.7782774259816776	yfinance_direct
5325	2026-02-05	EQ.SHEL	2769.2366	-97.49072265625	-3.4007672382701073	yfinance_direct
5326	2026-02-06	EQ.SHEL	2774.2361	4.99951171875	0.18053754485337076	yfinance_direct
5327	2026-02-09	EQ.SHEL	2822.7314	48.495361328125	1.748061803683112	yfinance_direct
5328	2026-02-10	EQ.SHEL	2831.7307	8.999267578125	0.31881416112288735	yfinance_direct
5329	2026-02-11	EQ.SHEL	2913.7229	81.9921875	2.895479684094062	yfinance_direct
5330	2026-02-12	EQ.SHEL	2887.7253	-25.99755859375	-0.8922454015879364	yfinance_direct
5331	2026-02-13	EQ.SHEL	2872.2268	-15.49853515625	-0.5367039216619577	yfinance_direct
5332	2026-02-16	EQ.SHEL	2865.2273	-6.99951171875	-0.24369634398533707	yfinance_direct
5333	2026-02-17	EQ.SHEL	2866.7273	1.5	0.052351867604308155	yfinance_direct
5334	2026-02-18	EQ.SHEL	2928.7214	61.994140625	2.1625405644553815	yfinance_direct
5335	2026-02-19	EQ.SHEL	2944	15.278564453125	0.5216803574311962	yfinance_direct
5336	2026-02-20	EQ.SHEL	2940.5	-3.5	-0.11888586956521739	yfinance_direct
5337	2026-02-23	EQ.SHEL	2965	24.5	0.8331916340758374	yfinance_direct
5338	2026-02-24	EQ.SHEL	2971.5	6.5	0.21922428330522767	yfinance_direct
5339	2026-02-25	EQ.SHEL	3011	39.5	1.3292949688709406	yfinance_direct
5340	2026-02-26	EQ.SHEL	3024	13	0.4317502490866822	yfinance_direct
5341	2026-02-27	EQ.SHEL	3073.5	49.5	1.6369047619047619	yfinance_direct
5342	2026-03-02	EQ.SHEL	3132	58.5	1.9033674963396778	yfinance_direct
5343	2026-03-03	EQ.SHEL	3113	-19	-0.6066411238825032	yfinance_direct
5344	2026-03-04	EQ.SHEL	3063.5	-49.5	-1.5901060070671378	yfinance_direct
5345	2026-03-05	EQ.SHEL	3108	44.5	1.4525869103966051	yfinance_direct
5346	2026-03-06	EQ.SHEL	3133	25	0.8043758043758044	yfinance_direct
5347	2026-03-09	EQ.SHEL	3207	74	2.3619533992977977	yfinance_direct
5348	2026-03-10	EQ.SHEL	3180.5	-26.5	-0.8263174306205177	yfinance_direct
5349	2026-03-11	EQ.SHEL	3244	63.5	1.9965414243043547	yfinance_direct
5350	2026-03-12	EQ.SHEL	3328	84	2.5893958076448826	yfinance_direct
5351	2026-03-13	EQ.SHEL	3367.5	39.5	1.1868990384615385	yfinance_direct
5352	2026-03-16	EQ.SHEL	3415	47.5	1.4105419450631032	yfinance_direct
5353	2026-03-17	EQ.SHEL	3474	59	1.7276720351390922	yfinance_direct
5354	2026-03-18	EQ.SHEL	3461.5	-12.5	-0.35981577432354633	yfinance_direct
5698	2025-07-23	EQ.LVMH	475.8427	14.27679443359375	3.0931212496098244	yfinance_direct
5699	2025-07-24	EQ.LVMH	466.2257	-9.61700439453125	-2.0210467717797402	yfinance_direct
5700	2025-07-25	EQ.LVMH	484.5179	18.292144775390625	3.92345236735454	yfinance_direct
5701	2025-07-28	EQ.LVMH	485.0136	0.4957275390625	0.10231356904421214	yfinance_direct
5702	2025-07-29	EQ.LVMH	470.7368	-14.27679443359375	-2.9435863477876887	yfinance_direct
5703	2025-07-30	EQ.LVMH	476.6359	5.899078369140625	1.2531584876186248	yfinance_direct
5704	2025-07-31	EQ.LVMH	468.3078	-8.328094482421875	-1.7472654858162533	yfinance_direct
5705	2025-08-01	EQ.LVMH	457.6993	-10.60845947265625	-2.265274989231378	yfinance_direct
5706	2025-08-04	EQ.LVMH	458.3438	0.644439697265625	0.14079978706340865	yfinance_direct
5707	2025-08-05	EQ.LVMH	452.5934	-5.7503662109375	-1.254596758015126	yfinance_direct
5708	2025-08-06	EQ.LVMH	453.7832	1.18975830078125	0.2628757430339378	yfinance_direct
5709	2025-08-07	EQ.LVMH	457.1541	3.370880126953125	0.7428393846303661	yfinance_direct
5710	2025-08-08	EQ.LVMH	457.4019	0.24786376953125	0.05421887174546583	yfinance_direct
5711	2025-08-11	EQ.LVMH	454.0806	-3.321319580078125	-0.726127167429514	yfinance_direct
5712	2025-08-12	EQ.LVMH	453.2379	-0.842742919921875	-0.18559324613979153	yfinance_direct
5713	2025-08-13	EQ.LVMH	465.5813	12.343475341796875	2.723399034911698	yfinance_direct
5714	2025-08-14	EQ.LVMH	468.8531	3.271728515625	0.7027190115683695	yfinance_direct
5715	2025-08-15	EQ.LVMH	472.0257	3.172637939453125	0.6766806542598024	yfinance_direct
5716	2025-08-18	EQ.LVMH	471.7778	-0.24786376953125	-0.052510651800587796	yfinance_direct
5717	2025-08-19	EQ.LVMH	485.7076	13.92974853515625	2.952607687220361	yfinance_direct
5718	2025-08-20	EQ.LVMH	489.3264	3.6187744140625	0.7450520763629999	yfinance_direct
5719	2025-08-21	EQ.LVMH	480.8495	-8.476837158203125	-1.7323483748471864	yfinance_direct
5720	2025-08-22	EQ.LVMH	490.8631	10.013580322265625	2.082476939483363	yfinance_direct
5721	2025-08-25	EQ.LVMH	483.8734	-6.98968505859375	-1.4239581433224149	yfinance_direct
5722	2025-08-26	EQ.LVMH	482.0888	-1.784576416015625	-0.36881059544775574	yfinance_direct
5723	2025-08-27	EQ.LVMH	497.704	15.615203857421875	3.2390718617932532	yfinance_direct
5724	2025-08-28	EQ.LVMH	508.709	11.0050048828125	2.2111544184274887	yfinance_direct
5725	2025-08-29	EQ.LVMH	499.7861	-8.9229736328125	-1.754042652341317	yfinance_direct
5726	2025-09-01	EQ.LVMH	499.3895	-0.396575927734375	-0.07934913558596543	yfinance_direct
5727	2025-09-02	EQ.LVMH	508.6099	9.220428466796875	1.8463400899352511	yfinance_direct
5728	2025-09-03	EQ.LVMH	516.3431	7.73321533203125	1.5204609588428748	yfinance_direct
5729	2025-09-04	EQ.LVMH	494.8289	-21.5142822265625	-4.166663711502186	yfinance_direct
5730	2025-09-05	EQ.LVMH	492.0033	-2.825592041015625	-0.5710241023002054	yfinance_direct
5731	2025-09-08	EQ.LVMH	491.9041	-0.099151611328125	-0.020152632778030814	yfinance_direct
5732	2025-09-09	EQ.LVMH	487.7896	-4.114501953125	-0.8364438999289894	yfinance_direct
5733	2025-09-10	EQ.LVMH	485.5589	-2.230743408203125	-0.45731671076314967	yfinance_direct
5734	2025-09-11	EQ.LVMH	483.1794	-2.37945556640625	-0.49004471367329083	yfinance_direct
5735	2025-09-12	EQ.LVMH	486.4512	3.271759033203125	0.6771312986951221	yfinance_direct
5736	2025-09-15	EQ.LVMH	499.8852	13.434051513671875	2.76164439318566	yfinance_direct
5737	2025-09-16	EQ.LVMH	503.3553	3.470062255859375	0.6941718005457673	yfinance_direct
5738	2025-09-17	EQ.LVMH	506.9244	3.56915283203125	0.709072286280069	yfinance_direct
5739	2025-09-18	EQ.LVMH	513.1705	6.24609375	1.2321547899270962	yfinance_direct
5740	2025-09-19	EQ.LVMH	506.2305	-6.9400634765625	-1.3523893210412348	yfinance_direct
5741	2025-09-22	EQ.LVMH	502.6613	-3.5692138671875	-0.7050571009684016	yfinance_direct
5742	2025-09-23	EQ.LVMH	518.7227	16.0614013671875	3.1952733995644764	yfinance_direct
5743	2025-09-24	EQ.LVMH	504.7433	-13.9793701171875	-2.694960389478361	yfinance_direct
5744	2025-09-25	EQ.LVMH	502.463	-2.28033447265625	-0.45178104103721123	yfinance_direct
5745	2025-09-26	EQ.LVMH	511.2868	8.8238525390625	1.7561200303242583	yfinance_direct
5746	2025-09-29	EQ.LVMH	518.6235	7.336669921875	1.4349421619370262	yfinance_direct
5747	2025-09-30	EQ.LVMH	516.0457	-2.5777587890625	-0.497038587277794	yfinance_direct
5748	2025-10-01	EQ.LVMH	519.5157	3.47003173828125	0.6724271968906053	yfinance_direct
5749	2025-10-02	EQ.LVMH	538.2541	18.73834228515625	3.6068862957141814	yfinance_direct
5750	2025-10-03	EQ.LVMH	548.3667	10.11260986328125	1.8787799411594948	yfinance_direct
5751	2025-10-06	EQ.LVMH	535.7755	-12.59124755859375	-2.2961364314303396	yfinance_direct
5752	2025-10-07	EQ.LVMH	555.2077	19.4322509765625	3.626939404623642	yfinance_direct
5753	2025-10-08	EQ.LVMH	570.5751	15.36737060546875	2.7678597635602085	yfinance_direct
5754	2025-10-09	EQ.LVMH	554.4146	-16.1605224609375	-2.8323218483955697	yfinance_direct
5755	2025-10-10	EQ.LVMH	541.3275	-13.0870361328125	-2.360514548972602	yfinance_direct
5756	2025-10-13	EQ.LVMH	535.7755	-5.55206298828125	-1.02563842369753	yfinance_direct
5757	2025-10-14	EQ.LVMH	528.2405	-7.53497314453125	-1.4063677462607418	yfinance_direct
5758	2025-10-15	EQ.LVMH	592.7834	64.54290771484375	12.21847062841751	yfinance_direct
5759	2025-10-16	EQ.LVMH	597.0466	4.26318359375	0.7191806809667424	yfinance_direct
5760	2025-10-17	EQ.LVMH	600.5166	3.47003173828125	0.5811995099985064	yfinance_direct
5761	2025-10-20	EQ.LVMH	606.8618	6.34521484375	1.056626049511407	yfinance_direct
5762	2025-10-21	EQ.LVMH	611.5216	4.6597900390625	0.7678502606502942	yfinance_direct
5763	2025-10-22	EQ.LVMH	617.8669	6.34527587890625	1.037620880771561	yfinance_direct
5764	2025-10-23	EQ.LVMH	615.4874	-2.3795166015625	-0.3851180035109691	yfinance_direct
5765	2025-10-24	EQ.LVMH	607.2584	-8.22894287109375	-1.3369799819419494	yfinance_direct
5766	2025-10-27	EQ.LVMH	606.267	-0.991455078125	-0.16326740656297986	yfinance_direct
5767	2025-10-28	EQ.LVMH	609.3405	3.073486328125	0.5069526283796423	yfinance_direct
5768	2025-10-29	EQ.LVMH	613.5045	4.1640625	0.6833720741780834	yfinance_direct
5769	2025-10-30	EQ.LVMH	604.879	-8.62554931640625	-1.4059471581703238	yfinance_direct
5770	2025-10-31	EQ.LVMH	606.8618	1.98284912109375	0.32780923595231926	yfinance_direct
5771	2025-11-03	EQ.LVMH	611.5216	4.6597900390625	0.7678502606502942	yfinance_direct
5772	2025-11-04	EQ.LVMH	605.9695	-5.55206298828125	-0.907909537416772	yfinance_direct
5773	2025-11-05	EQ.LVMH	607.5558	1.5863037109375	0.2617794455291767	yfinance_direct
5774	2025-11-06	EQ.LVMH	594.8654	-12.6904296875	-2.0887675999917623	yfinance_direct
5872	2024-03-26	EQ.ASML	954.8553	-7.50079345703125	-0.7794197121208826	yfinance_direct
5873	2024-03-27	EQ.ASML	957.5197	2.664306640625	0.27902725265031786	yfinance_direct
5874	2024-03-28	EQ.ASML	954.0394	-3.48028564453125	-0.3634688470845427	yfinance_direct
5875	2024-04-01	EQ.ASML	976.1388	22.09942626953125	2.3164061168009864	yfinance_direct
5876	2024-04-02	EQ.ASML	950.3431	-25.79571533203125	-2.642627820145466	yfinance_direct
5877	2024-04-03	EQ.ASML	963.6736	13.33050537109375	1.4027045254588812	yfinance_direct
5878	2024-04-04	EQ.ASML	937.2681	-26.40545654296875	-2.740083051129571	yfinance_direct
5879	2024-04-05	EQ.ASML	962.9657	25.69757080078125	2.74175233835504	yfinance_direct
5880	2024-04-08	EQ.ASML	966.0722	3.10650634765625	0.3225978197693765	yfinance_direct
5881	2024-04-09	EQ.ASML	973.0716	6.9993896484375	0.724520342804932	yfinance_direct
5882	2024-04-10	EQ.ASML	958.1093	-14.96234130859375	-1.5376403336803028	yfinance_direct
5883	2024-04-11	EQ.ASML	975.3818	17.2725830078125	1.8027780187903142	yfinance_direct
5884	2024-04-12	EQ.ASML	945.5555	-29.8262939453125	-3.0579095126007343	yfinance_direct
5885	2024-04-15	EQ.ASML	938.6544	-6.90118408203125	-0.7298549662657754	yfinance_direct
5886	2024-04-16	EQ.ASML	960.3802	21.72589111328125	2.314578410060581	yfinance_direct
5887	2024-04-17	EQ.ASML	892.2437	-68.13653564453125	-7.094745619124912	yfinance_direct
5888	2024-04-18	EQ.ASML	873.9783	-18.265380859375	-2.04712911791829	yfinance_direct
5889	2024-04-19	EQ.ASML	844.9875	-28.99078369140625	-3.3171055405722405	yfinance_direct
5890	2024-04-22	EQ.ASML	857.2858	12.2982177734375	1.4554318333439755	yfinance_direct
5891	2024-04-23	EQ.ASML	886.3059	29.0201416015625	3.385118793772075	yfinance_direct
5892	2024-04-24	EQ.ASML	877.2126	-9.09332275390625	-1.0259801576119278	yfinance_direct
5893	2024-04-25	EQ.ASML	887.23	10.01739501953125	1.1419575124314207	yfinance_direct
5894	2024-04-26	EQ.ASML	905.2901	18.06011962890625	2.0355623712540183	yfinance_direct
5895	2024-04-29	EQ.ASML	896.2271	-9.06304931640625	-1.0011210014810272	yfinance_direct
5896	2024-04-30	EQ.ASML	859.4822	-36.74481201171875	-4.099944537457103	yfinance_direct
5897	2024-05-01	EQ.ASML	840.1445	-19.33770751953125	-2.2499252046459826	yfinance_direct
5898	2024-05-02	EQ.ASML	857.325	17.180419921875	2.044936232140117	yfinance_direct
5899	2024-05-03	EQ.ASML	888.2083	30.88330078125	3.602286477144484	yfinance_direct
5900	2024-05-06	EQ.ASML	903.2706	15.06231689453125	1.6958091597786868	yfinance_direct
5901	2024-05-07	EQ.ASML	894.7001	-8.5704345703125	-0.948822519618479	yfinance_direct
5902	2024-05-08	EQ.ASML	897.9018	3.20166015625	0.3578472868829964	yfinance_direct
5903	2024-05-09	EQ.ASML	899.9409	2.0390625	0.2270919283869193	yfinance_direct
5904	2024-05-10	EQ.ASML	916.4416	16.500732421875	1.8335352034242158	yfinance_direct
5905	2024-05-13	EQ.ASML	903.5858	-12.85577392578125	-1.4027925047381018	yfinance_direct
5906	2024-05-14	EQ.ASML	901.4087	-2.1771240234375	-0.2409426958968141	yfinance_direct
5907	2024-05-15	EQ.ASML	923.4654	22.05670166015625	2.4469146870268705	yfinance_direct
5908	2024-05-16	EQ.ASML	905.8516	-17.61376953125	-1.907355669578773	yfinance_direct
5909	2024-05-17	EQ.ASML	911.2008	5.34918212890625	0.59051416257672	yfinance_direct
5910	2024-05-20	EQ.ASML	925.4554	14.25457763671875	1.564372808727966	yfinance_direct
5911	2024-05-21	EQ.ASML	911.4963	-13.95904541015625	-1.5083434233608468	yfinance_direct
5912	2024-05-22	EQ.ASML	908.6001	-2.896240234375	-0.3177456797113906	yfinance_direct
5913	2024-05-23	EQ.ASML	920.3427	11.7425537109375	1.2923786538464639	yfinance_direct
5914	2024-05-24	EQ.ASML	941.9855	21.64288330078125	2.351611464342146	yfinance_direct
5915	2024-05-28	EQ.ASML	977.0853	35.0997314453125	3.7261433592697855	yfinance_direct
5916	2024-05-29	EQ.ASML	943.6209	-33.46435546875	-3.42491659933292	yfinance_direct
5917	2024-05-30	EQ.ASML	951.7382	8.11724853515625	0.8602234693603643	yfinance_direct
5918	2024-05-31	EQ.ASML	946.0542	-5.6839599609375	-0.597218878544973	yfinance_direct
5919	2024-06-03	EQ.ASML	951.1077	5.05352783203125	0.5341689552463743	yfinance_direct
5920	2024-06-04	EQ.ASML	936.6561	-14.45159912109375	-1.5194492390368473	yfinance_direct
5921	2024-06-05	EQ.ASML	1025.8385	89.182373046875	9.521356919320738	yfinance_direct
5922	2024-06-06	EQ.ASML	1036.9406	11.10205078125	1.082241578053586	yfinance_direct
5923	2024-06-07	EQ.ASML	1013.1109	-23.82965087890625	-2.298073003173657	yfinance_direct
5924	2024-06-10	EQ.ASML	1026.203	13.09210205078125	1.2922674150898417	yfinance_direct
5925	2024-06-11	EQ.ASML	1020.588	-5.61505126953125	-0.547167690359602	yfinance_direct
5926	2024-06-12	EQ.ASML	1052.9489	32.36090087890625	3.1708096128575547	yfinance_direct
5927	2024-06-13	EQ.ASML	1037.0391	-15.9097900390625	-1.5109746309802143	yfinance_direct
5928	2024-06-14	EQ.ASML	1012.5986	-24.44049072265625	-2.356757002357975	yfinance_direct
5929	2024-06-17	EQ.ASML	1036.8027	24.20416259765625	2.3903018700858296	yfinance_direct
5930	2024-06-18	EQ.ASML	1045.5802	8.7774658203125	0.8465897638284766	yfinance_direct
5931	2024-06-20	EQ.ASML	1035.0985	-10.481689453125	-1.002475893400338	yfinance_direct
5932	2024-06-21	EQ.ASML	1021.1689	-13.92962646484375	-1.3457295436408185	yfinance_direct
5933	2024-06-24	EQ.ASML	987.094	-34.07489013671875	-3.3368515885433307	yfinance_direct
5934	2024-06-25	EQ.ASML	1008.1064	21.012451171875	2.128718368929868	yfinance_direct
5935	2024-06-26	EQ.ASML	1001.4668	-6.6396484375	-0.6586257302860309	yfinance_direct
5936	2024-06-27	EQ.ASML	1012.7069	11.2401123046875	1.1223649490688463	yfinance_direct
5937	2024-06-28	EQ.ASML	1007.5056	-5.20135498046875	-0.5136091136854146	yfinance_direct
5938	2024-07-01	EQ.ASML	1018.1053	10.59979248046875	1.0520827836918112	yfinance_direct
5939	2024-07-02	EQ.ASML	1032.2909	14.185546875	1.3933280010033189	yfinance_direct
5940	2024-07-03	EQ.ASML	1055.4611	23.170166015625	2.244538449413098	yfinance_direct
5941	2024-07-05	EQ.ASML	1058.485	3.02392578125	0.28650282772924535	yfinance_direct
5942	2024-07-08	EQ.ASML	1061.3518	2.8668212890625	0.27084194190154914	yfinance_direct
5943	2024-07-09	EQ.ASML	1044.1913	-17.1605224609375	-1.6168552551159951	yfinance_direct
5944	2024-07-10	EQ.ASML	1082.5909	38.399658203125	3.677454388377855	yfinance_direct
5945	2024-07-11	EQ.ASML	1046.6835	-35.907470703125	-3.3168087130021306	yfinance_direct
5946	2024-07-12	EQ.ASML	1069.1047	22.4212646484375	2.14212464943738	yfinance_direct
5947	2024-07-15	EQ.ASML	1047.7966	-21.30810546875	-1.9930793255984798	yfinance_direct
5948	2024-07-16	EQ.ASML	1052.2887	4.4920654296875	0.42871539165030786	yfinance_direct
5949	2024-07-17	EQ.ASML	918.1852	-134.103515625	-12.74398519131882	yfinance_direct
5950	2024-07-18	EQ.ASML	910.393	-7.79217529296875	-0.8486496468319371	yfinance_direct
5951	2024-07-19	EQ.ASML	882.0414	-28.35162353515625	-3.1142180759176177	yfinance_direct
5952	2024-07-22	EQ.ASML	927.2482	45.20684814453125	5.125252519381212	yfinance_direct
5953	2024-07-23	EQ.ASML	918.9241	-8.32415771484375	-0.8977269997074124	yfinance_direct
5954	2024-07-24	EQ.ASML	859.7582	-59.1658935546875	-6.438605249377443	yfinance_direct
5955	2024-07-25	EQ.ASML	849.7888	-9.96942138671875	-1.1595610991065206	yfinance_direct
5956	2024-07-26	EQ.ASML	875.1654	25.37664794921875	2.9862301343128776	yfinance_direct
5957	2024-07-29	EQ.ASML	859.1799	-15.9854736328125	-1.8265659881537462	yfinance_direct
5958	2024-07-30	EQ.ASML	849.0045	-10.1754150390625	-1.1843171219830866	yfinance_direct
5959	2024-07-31	EQ.ASML	924.4659	75.46142578125	8.8882243033654	yfinance_direct
5960	2024-08-01	EQ.ASML	872.1682	-52.29779052734375	-5.657081362299417	yfinance_direct
5961	2024-08-02	EQ.ASML	798.7792	-73.38897705078125	-8.414544476847958	yfinance_direct
5962	2024-08-05	EQ.ASML	809.6355	10.8563232421875	1.3591144567385625	yfinance_direct
5963	2024-08-06	EQ.ASML	831.9996	22.36407470703125	2.762239892023169	yfinance_direct
5964	2024-08-07	EQ.ASML	825.4265	-6.57305908203125	-0.7900315453617989	yfinance_direct
5965	2024-08-08	EQ.ASML	865.2002	39.773681640625	4.818561190104429	yfinance_direct
5966	2024-08-09	EQ.ASML	849.3105	-15.88970947265625	-1.8365355854915262	yfinance_direct
5967	2024-08-12	EQ.ASML	841.7209	-7.58953857421875	-0.8936117828233108	yfinance_direct
5968	2024-08-13	EQ.ASML	858.1337	16.41278076171875	1.9499076047752566	yfinance_direct
5969	2024-08-14	EQ.ASML	868.0919	9.95819091796875	1.160447444579575	yfinance_direct
5970	2024-08-15	EQ.ASML	916.1262	48.0343017578125	5.5333197682765825	yfinance_direct
5971	2024-08-16	EQ.ASML	906.6614	-9.46478271484375	-1.0331308613325736	yfinance_direct
5972	2024-08-19	EQ.ASML	920.9623	14.3009033203125	1.5773146095243262	yfinance_direct
5973	2024-08-20	EQ.ASML	914.0833	-6.87908935546875	-0.7469457812676971	yfinance_direct
5974	2024-08-21	EQ.ASML	931.2856	17.20233154296875	1.8819217512422928	yfinance_direct
5975	2024-08-22	EQ.ASML	895.8546	-35.4310302734375	-3.804529018953305	yfinance_direct
5976	2024-08-23	EQ.ASML	895.4104	-0.44415283203125	-0.04957867663154691	yfinance_direct
5977	2024-08-26	EQ.ASML	871.7732	-23.63720703125	-2.639818235407832	yfinance_direct
5978	2024-08-27	EQ.ASML	878.2574	6.4842529296875	0.743800449369228	yfinance_direct
5979	2024-08-28	EQ.ASML	876.5303	-1.7271728515625	-0.19665906151554932	yfinance_direct
5980	2024-08-29	EQ.ASML	876.1158	-0.41448974609375	-0.04728755624928278	yfinance_direct
5981	2024-08-30	EQ.ASML	892.0646	15.9488525390625	1.8204046583733453	yfinance_direct
5982	2024-09-03	EQ.ASML	834.3485	-57.71612548828125	-6.469948829287527	yfinance_direct
5983	2024-09-04	EQ.ASML	800.8813	-33.4671630859375	-4.011173107526383	yfinance_direct
5984	2024-09-05	EQ.ASML	785.2087	-15.672607421875	-1.9569200191439484	yfinance_direct
5985	2024-09-06	EQ.ASML	742.958	-42.250732421875	-5.380828085187091	yfinance_direct
5986	2024-09-09	EQ.ASML	740.0268	-2.93121337890625	-0.39453284682086626	yfinance_direct
5987	2024-09-10	EQ.ASML	741.5663	1.53955078125	0.2080398700196188	yfinance_direct
5988	2024-09-11	EQ.ASML	789.6895	48.1231689453125	6.489394948387314	yfinance_direct
5989	2024-09-12	EQ.ASML	789.7192	0.0296630859375	0.0037562973049030577	yfinance_direct
5990	2024-09-13	EQ.ASML	805.6976	15.97845458984375	2.023308417754748	yfinance_direct
5991	2024-09-16	EQ.ASML	792.5515	-13.1461181640625	-1.6316441360397862	yfinance_direct
5992	2024-09-17	EQ.ASML	795.167	2.615478515625	0.330007383811248	yfinance_direct
5993	2024-09-18	EQ.ASML	777.5502	-17.6168212890625	-2.215486993568322	yfinance_direct
5994	2024-09-19	EQ.ASML	817.3434	39.79327392578125	5.117775728838338	yfinance_direct
5995	2024-09-20	EQ.ASML	784.8929	-32.45050048828125	-3.970240502174724	yfinance_direct
5996	2024-09-23	EQ.ASML	793.0056	8.1126708984375	1.0336022201475215	yfinance_direct
5997	2024-09-24	EQ.ASML	803.3684	10.36279296875	1.3067742232427002	yfinance_direct
5998	2024-09-25	EQ.ASML	807.4938	4.12542724609375	0.5135162403661099	yfinance_direct
5999	2024-09-26	EQ.ASML	841.3065	33.8126220703125	4.187353585368503	yfinance_direct
6000	2024-09-27	EQ.ASML	830.5488	-10.7576904296875	-1.278688679200796	yfinance_direct
6001	2024-09-30	EQ.ASML	822.3671	-8.18170166015625	-0.9850958768892137	yfinance_direct
6002	2024-10-01	EQ.ASML	811.6094	-10.7576904296875	-1.3081373126326012	yfinance_direct
6003	2024-10-02	EQ.ASML	821.3209	9.7115478515625	1.1965790626263404	yfinance_direct
6004	2024-10-03	EQ.ASML	821.538	0.21710205078125	0.026433278970598793	yfinance_direct
6005	2024-10-04	EQ.ASML	822.1203	0.582275390625	0.07087625562970322	yfinance_direct
6006	2024-10-07	EQ.ASML	806.576	-15.54425048828125	-1.890751327116231	yfinance_direct
6007	2024-10-08	EQ.ASML	813.4944	6.91839599609375	0.8577487513755263	yfinance_direct
6008	2024-10-09	EQ.ASML	834.8518	21.35736083984375	2.6253849611499387	yfinance_direct
6009	2024-10-10	EQ.ASML	823.0776	-11.774169921875	-1.410330531505141	yfinance_direct
6010	2024-10-11	EQ.ASML	829.7099	6.63226318359375	0.8057882862707433	yfinance_direct
6011	2024-10-14	EQ.ASML	860.8775	31.1676025390625	3.756445782162043	yfinance_direct
6012	2024-10-15	EQ.ASML	720.89	-139.98748779296875	-16.26102289767953	yfinance_direct
6013	2024-10-16	EQ.ASML	674.5927	-46.29736328125	-6.422250598633721	yfinance_direct
6014	2024-10-17	EQ.ASML	691.4495	16.8568115234375	2.4988133934269867	yfinance_direct
6015	2024-10-18	EQ.ASML	713.8137	22.36419677734375	3.2343935424939896	yfinance_direct
6016	2024-10-21	EQ.ASML	704.7733	-9.0404052734375	-1.2664937341830436	yfinance_direct
6017	2024-10-22	EQ.ASML	711.4943	6.72100830078125	0.9536412255818717	yfinance_direct
6018	2024-10-23	EQ.ASML	699.3649	-12.12939453125	-1.7047775600186736	yfinance_direct
6019	2024-10-24	EQ.ASML	701.5262	2.16131591796875	0.3090398183200892	yfinance_direct
6020	2024-10-25	EQ.ASML	702.4046	0.87841796875	0.12521527901334675	yfinance_direct
6021	2024-10-28	EQ.ASML	699.3945	-3.0101318359375	-0.4285467132688118	yfinance_direct
6022	2024-10-29	EQ.ASML	707.4379	8.04345703125	1.1500601411359697	yfinance_direct
6023	2024-10-30	EQ.ASML	676.4651	-30.97283935546875	-4.37817060162995	yfinance_direct
6024	2024-10-31	EQ.ASML	665.3065	-11.1585693359375	-1.6495410532910881	yfinance_direct
6025	2024-11-01	EQ.ASML	667.4631	2.15655517578125	0.32414460337261575	yfinance_direct
6026	2024-11-04	EQ.ASML	663.9315	-3.53155517578125	-0.5291012064597513	yfinance_direct
6027	2024-11-05	EQ.ASML	669.1745	5.24298095703125	0.7896870099561917	yfinance_direct
6028	2024-11-06	EQ.ASML	654.3063	-14.86822509765625	-2.2218756256410326	yfinance_direct
6029	2024-11-07	EQ.ASML	669.9164	15.610107421875	2.385749309198357	yfinance_direct
6030	2024-11-08	EQ.ASML	662.2598	-7.6566162109375	-1.1429211792006313	yfinance_direct
6031	2024-11-11	EQ.ASML	664.0799	1.82012939453125	0.2748361729046795	yfinance_direct
6032	2024-11-12	EQ.ASML	661.9729	-2.10699462890625	-0.3172802918305908	yfinance_direct
6033	2024-11-13	EQ.ASML	666.1573	4.18438720703125	0.632108535645806	yfinance_direct
6034	2024-11-14	EQ.ASML	685.4968	19.33953857421875	2.9031489911282615	yfinance_direct
6035	2024-11-15	EQ.ASML	651.5366	-33.96026611328125	-4.954109897624292	yfinance_direct
6036	2024-11-18	EQ.ASML	658.0654	6.52880859375	1.002063275338356	yfinance_direct
6037	2024-11-19	EQ.ASML	655.0284	-3.03692626953125	-0.4614930999561017	yfinance_direct
6038	2024-11-20	EQ.ASML	651.3387	-3.68975830078125	-0.5632974176447864	yfinance_direct
6039	2024-11-21	EQ.ASML	664.9208	13.58209228515625	2.085258041183024	yfinance_direct
6040	2024-11-22	EQ.ASML	665.633	0.71221923828125	0.10711339810623438	yfinance_direct
6041	2024-11-25	EQ.ASML	677.0981	11.46514892578125	1.72244299808972	yfinance_direct
6042	2024-11-26	EQ.ASML	664.7328	-12.3653564453125	-1.8262280801069015	yfinance_direct
6043	2024-11-27	EQ.ASML	663.2589	-1.47393798828125	-0.22173390792492356	yfinance_direct
6044	2024-11-29	EQ.ASML	679.2151	15.95623779296875	2.405733114698643	yfinance_direct
6045	2024-12-02	EQ.ASML	703.8074	24.59228515625	3.6206918242384702	yfinance_direct
6046	2024-12-03	EQ.ASML	710.3264	6.51904296875	0.9262538612700522	yfinance_direct
6047	2024-12-04	EQ.ASML	712.1663	1.83990478515625	0.2590224358368474	yfinance_direct
6048	2024-12-05	EQ.ASML	703.837	-8.32928466796875	-1.1695701445981117	yfinance_direct
6049	2024-12-06	EQ.ASML	701.3442	-2.4927978515625	-0.35417258876557817	yfinance_direct
6050	2024-12-09	EQ.ASML	698.9107	-2.43353271484375	-0.3469812086583173	yfinance_direct
6051	2024-12-10	EQ.ASML	697.6742	-1.23651123046875	-0.17691977252897642	yfinance_direct
6052	2024-12-11	EQ.ASML	706.7355	9.061279296875	1.2987837833818314	yfinance_direct
6053	2024-12-12	EQ.ASML	705.4199	-1.31561279296875	-0.18615349618806348	yfinance_direct
6054	2024-12-13	EQ.ASML	710.8408	5.42095947265625	0.7684727597834118	yfinance_direct
6055	2024-12-16	EQ.ASML	714.5999	3.75909423828125	0.5288236312355664	yfinance_direct
6056	2024-12-17	EQ.ASML	727.2719	12.6719970703125	1.7732995501795565	yfinance_direct
6057	2024-12-18	EQ.ASML	711.7411	-15.53082275390625	-2.1354905236595685	yfinance_direct
6058	2024-12-19	EQ.ASML	702.6105	-9.130615234375	-1.2828562769795062	yfinance_direct
6059	2024-12-20	EQ.ASML	698.0797	-4.53076171875	-0.6448468801388516	yfinance_direct
6060	2024-12-23	EQ.ASML	713.2743	15.194580078125	2.1766253650980674	yfinance_direct
6061	2024-12-24	EQ.ASML	711.9587	-1.31561279296875	-0.18444696629878818	yfinance_direct
6062	2024-12-26	EQ.ASML	708.1501	-3.80853271484375	-0.5349373251727794	yfinance_direct
6063	2024-12-27	EQ.ASML	705.9045	-2.24560546875	-0.31710866401685456	yfinance_direct
6064	2024-12-30	EQ.ASML	688.6524	-17.25213623046875	-2.4439758109003127	yfinance_direct
6065	2024-12-31	EQ.ASML	685.6154	-3.0369873046875	-0.44100438531612624	yfinance_direct
6066	2025-01-02	EQ.ASML	692.8764	7.260986328125	1.0590465358565022	yfinance_direct
6067	2025-01-03	EQ.ASML	706.6663	13.78985595703125	1.9902331615323243	yfinance_direct
6068	2025-01-06	EQ.ASML	760.233	53.5667724609375	7.580208014841916	yfinance_direct
6069	2025-01-07	EQ.ASML	749.4208	-10.812255859375	-1.4222291588288631	yfinance_direct
6070	2025-01-08	EQ.ASML	735.9673	-13.4534912109375	-1.7951852464183358	yfinance_direct
6071	2025-01-10	EQ.ASML	731.0508	-4.91650390625	-0.6680329418727082	yfinance_direct
6072	2025-01-13	EQ.ASML	719.5756	-11.47515869140625	-1.5696801078285216	yfinance_direct
6073	2025-01-14	EQ.ASML	728.3601	8.78448486328125	1.2207868899235736	yfinance_direct
6074	2025-01-15	EQ.ASML	718.4777	-9.8824462890625	-1.3568077367722264	yfinance_direct
6075	2025-01-16	EQ.ASML	742.1995	23.7218017578125	3.301675617918406	yfinance_direct
6076	2025-01-17	EQ.ASML	748.1843	5.98480224609375	0.8063603580073874	yfinance_direct
6077	2025-01-21	EQ.ASML	754.7825	6.59820556640625	0.8818957941063533	yfinance_direct
6078	2025-01-22	EQ.ASML	758.4525	3.6700439453125	0.486238630037822	yfinance_direct
6079	2025-01-23	EQ.ASML	738.2029	-20.2496337890625	-2.6698617774968723	yfinance_direct
6080	2025-01-24	EQ.ASML	724.3635	-13.83935546875	-1.8747360417557553	yfinance_direct
6081	2025-01-27	EQ.ASML	682.717	-41.646484375	-5.749390039005822	yfinance_direct
6082	2025-01-28	EQ.ASML	675.9902	-6.726806640625	-0.9852993607158324	yfinance_direct
6083	2025-01-29	EQ.ASML	704.9748	28.98455810546875	4.287718465676799	yfinance_direct
6084	2025-01-30	EQ.ASML	729.0526	24.0777587890625	3.4154070536826424	yfinance_direct
6085	2025-01-31	EQ.ASML	731.3476	2.2950439453125	0.31479815019041346	yfinance_direct
6086	2025-02-03	EQ.ASML	723.1865	-8.1611328125	-1.1159034180050256	yfinance_direct
6087	2025-02-04	EQ.ASML	723.5327	0.34619140625	0.04787028301110494	yfinance_direct
6088	2025-02-05	EQ.ASML	734.5922	11.0595703125	1.5285516492287774	yfinance_direct
6089	2025-02-06	EQ.ASML	731.1695	-3.4227294921875	-0.46593598186839513	yfinance_direct
6090	2025-02-07	EQ.ASML	719.8626	-11.306884765625	-1.546410900438842	yfinance_direct
6091	2025-02-10	EQ.ASML	736.0662	16.20361328125	2.25093136651832	yfinance_direct
6092	2025-02-11	EQ.ASML	746.4453	10.37908935546875	1.4100754835792473	yfinance_direct
6093	2025-02-12	EQ.ASML	749.6076	3.16229248046875	0.42364690721649484	yfinance_direct
6094	2025-02-13	EQ.ASML	770.2469	20.63934326171875	2.7533529708862163	yfinance_direct
6095	2025-02-14	EQ.ASML	745.0278	-25.21917724609375	-3.2741677592683076	yfinance_direct
6096	2025-02-18	EQ.ASML	737.7614	-7.26641845703125	-0.9753218255631102	yfinance_direct
6097	2025-02-19	EQ.ASML	738.3363	0.574951171875	0.07793186372480224	yfinance_direct
6098	2025-02-20	EQ.ASML	736.6412	-1.695068359375	-0.22957944108334513	yfinance_direct
6099	2025-02-21	EQ.ASML	730.8123	-5.8289794921875	-0.7912915015415362	yfinance_direct
6100	2025-02-24	EQ.ASML	729.5731	-1.23919677734375	-0.16956431250411322	yfinance_direct
6101	2025-02-25	EQ.ASML	723.8531	-5.71990966796875	-0.7840077969937235	yfinance_direct
6102	2025-02-26	EQ.ASML	740.4478	16.59466552734375	2.2925458762977873	yfinance_direct
6103	2025-02-27	EQ.ASML	691.645	-48.80279541015625	-6.590983783782002	yfinance_direct
6104	2025-02-28	EQ.ASML	702.9263	11.28131103515625	1.631083968883627	yfinance_direct
6105	2025-03-03	EQ.ASML	693.7863	-9.1400146484375	-1.3002805914344722	yfinance_direct
6106	2025-03-04	EQ.ASML	702.0737	8.28741455078125	1.194519747743357	yfinance_direct
6107	2025-03-05	EQ.ASML	733.3301	31.25634765625	4.452003585917	yfinance_direct
6108	2025-03-06	EQ.ASML	708.6364	-24.6937255859375	-3.3673411636237733	yfinance_direct
6109	2025-03-07	EQ.ASML	725.8654	17.22906494140625	2.4312984903574395	yfinance_direct
6110	2025-03-10	EQ.ASML	677.1816	-48.68377685546875	-6.706997699994257	yfinance_direct
6111	2025-03-11	EQ.ASML	684.2201	7.0384521484375	1.0393743312269084	yfinance_direct
6112	2025-03-12	EQ.ASML	697.2658	13.04571533203125	1.906654813241653	yfinance_direct
6113	2025-03-13	EQ.ASML	688.5621	-8.7037353515625	-1.248266478921618	yfinance_direct
6114	2025-03-14	EQ.ASML	707.8037	19.24163818359375	2.7944667510710772	yfinance_direct
6115	2025-03-17	EQ.ASML	723.9919	16.188232421875	2.287107593775309	yfinance_direct
6116	2025-03-18	EQ.ASML	724.7651	0.77313232421875	0.10678742095269184	yfinance_direct
6117	2025-03-19	EQ.ASML	728.5321	3.76702880859375	0.5197585997146335	yfinance_direct
6118	2025-03-20	EQ.ASML	727.6896	-0.842529296875	-0.11564751802698833	yfinance_direct
6119	2025-03-21	EQ.ASML	710.0043	-17.68524169921875	-2.4303277526645912	yfinance_direct
6120	2025-03-24	EQ.ASML	721.5235	11.5191650390625	1.622407708744763	yfinance_direct
6121	2025-03-25	EQ.ASML	720.4331	-1.09039306640625	-0.15112370818413762	yfinance_direct
6122	2025-03-26	EQ.ASML	699.6351	-20.7979736328125	-2.8868708940409245	yfinance_direct
6123	2025-03-27	EQ.ASML	684.6365	-14.9986572265625	-2.143782743900237	yfinance_direct
6124	2025-03-28	EQ.ASML	668.7258	-15.91070556640625	-2.323964053402827	yfinance_direct
6125	2025-03-31	EQ.ASML	656.8795	-11.8463134765625	-1.771475547221109	yfinance_direct
6126	2025-04-01	EQ.ASML	661.5486	4.66912841796875	0.7108044525372937	yfinance_direct
6127	2025-04-02	EQ.ASML	663.2041	1.655517578125	0.25024882800808795	yfinance_direct
6128	2025-04-03	EQ.ASML	617.8114	-45.3927001953125	-6.844454081084225	yfinance_direct
6129	2025-04-04	EQ.ASML	600.2947	-17.51666259765625	-2.835276681345262	yfinance_direct
6130	2025-04-07	EQ.ASML	610.4955	10.2008056640625	1.6992995282570442	yfinance_direct
6131	2025-04-08	EQ.ASML	590.2031	-20.29241943359375	-3.32392588588352	yfinance_direct
6132	2025-04-09	EQ.ASML	681.2957	91.09259033203125	15.434108440552777	yfinance_direct
6133	2025-04-10	EQ.ASML	643.9129	-37.3828125	-5.487017114408446	yfinance_direct
6134	2025-04-11	EQ.ASML	663.0059	19.09295654296875	2.9651458231377092	yfinance_direct
6135	2025-04-14	EQ.ASML	667.0305	4.024658203125	0.6070320716198422	yfinance_direct
6136	2025-04-15	EQ.ASML	677.2312	10.20068359375	1.5292679007831542	yfinance_direct
6137	2025-04-16	EQ.ASML	629.4199	-47.81134033203125	-7.059825396304677	yfinance_direct
6138	2025-04-17	EQ.ASML	634.6044	5.1845703125	0.8237061832752076	yfinance_direct
6139	2025-04-21	EQ.ASML	619.2687	-15.33575439453125	-2.4165848269738497	yfinance_direct
6140	2025-04-22	EQ.ASML	633.1472	13.8785400390625	2.2411177183583284	yfinance_direct
6141	2025-04-23	EQ.ASML	652.2697	19.12249755859375	3.0202292691635715	yfinance_direct
6142	2025-04-24	EQ.ASML	669.142	16.872314453125	2.58670824074626	yfinance_direct
6143	2025-04-25	EQ.ASML	671.3924	2.2503662109375	0.33630621214217754	yfinance_direct
6144	2025-04-28	EQ.ASML	668.9869	-2.40545654296875	-0.3582787890975104	yfinance_direct
6145	2025-04-29	EQ.ASML	662.3743	-6.6126708984375	-0.9884603895998443	yfinance_direct
6146	2025-04-30	EQ.ASML	664.3332	1.95892333984375	0.2957426693229294	yfinance_direct
6147	2025-05-01	EQ.ASML	662.9808	-1.35235595703125	-0.20356591775319527	yfinance_direct
6148	2025-05-02	EQ.ASML	686.4584	23.47760009765625	3.5412185178836335	yfinance_direct
6149	2025-05-05	EQ.ASML	679.5275	-6.93096923828125	-1.0096706347107012	yfinance_direct
6150	2025-05-06	EQ.ASML	676.1764	-3.35107421875	-0.49314772210195323	yfinance_direct
6151	2025-05-07	EQ.ASML	696.462	20.28558349609375	3.0000431467366355	yfinance_direct
6152	2025-05-08	EQ.ASML	704.0591	7.59716796875	1.0908230801379706	yfinance_direct
6153	2025-05-09	EQ.ASML	702.2494	-1.80975341796875	-0.2570456524556568	yfinance_direct
6154	2025-05-12	EQ.ASML	745.9927	43.7432861328125	6.229024443112925	yfinance_direct
6155	2025-05-13	EQ.ASML	759.6158	13.62310791015625	1.8261718046882005	yfinance_direct
6156	2025-05-14	EQ.ASML	764.5977	4.98193359375	0.6558491411987181	yfinance_direct
6157	2025-05-15	EQ.ASML	754.1069	-10.4908447265625	-1.3720737702189536	yfinance_direct
6158	2025-05-16	EQ.ASML	743.9044	-10.20245361328125	-1.3529187950065424	yfinance_direct
6159	2025-05-19	EQ.ASML	744.9286	1.02423095703125	0.1376831392510582	yfinance_direct
6160	2025-05-20	EQ.ASML	744.5608	-0.36785888671875	-0.0493817611615521	yfinance_direct
6161	2025-05-21	EQ.ASML	733.0357	-11.52508544921875	-1.5479038902247124	yfinance_direct
6162	2025-05-22	EQ.ASML	736.546	3.51025390625	0.47886533760830613	yfinance_direct
6163	2025-05-23	EQ.ASML	728.3819	-8.1640625	-1.1084254003436815	yfinance_direct
6164	2025-05-27	EQ.ASML	752.5457	24.16375732421875	3.317457150520844	yfinance_direct
6165	2025-05-28	EQ.ASML	742.3234	-10.2222900390625	-1.358361447002638	yfinance_direct
6166	2025-05-29	EQ.ASML	742.8802	0.55682373046875	0.07501093960924587	yfinance_direct
6167	2025-05-30	EQ.ASML	732.638	-10.2421875	-1.3787132387708216	yfinance_direct
6168	2025-06-02	EQ.ASML	742.3433	9.70526123046875	1.3247007695479192	yfinance_direct
6169	2025-06-03	EQ.ASML	743.0591	0.71588134765625	0.09643535336991776	yfinance_direct
6170	2025-06-04	EQ.ASML	738.6143	-4.44482421875	-0.5981790628949668	yfinance_direct
6171	2025-06-05	EQ.ASML	743.5663	4.95196533203125	0.670439931323972	yfinance_direct
6172	2025-06-06	EQ.ASML	748.7968	5.23052978515625	0.7034382672321732	yfinance_direct
6173	2025-06-09	EQ.ASML	765.8805	17.08367919921875	2.2814839594150347	yfinance_direct
6174	2025-06-10	EQ.ASML	780.5676	14.6871337890625	1.9176795753585418	yfinance_direct
6175	2025-06-11	EQ.ASML	779.6926	-0.87506103515625	-0.11210572984841448	yfinance_direct
6176	2025-06-12	EQ.ASML	781.8007	2.108154296875	0.27038276226129854	yfinance_direct
6177	2025-06-13	EQ.ASML	756.7321	-25.06866455078125	-3.2065287102693154	yfinance_direct
6178	2025-06-16	EQ.ASML	770.8823	14.15020751953125	1.869909886018226	yfinance_direct
6179	2025-06-17	EQ.ASML	755.5984	-15.2838134765625	-1.9826391404367412	yfinance_direct
6180	2025-06-18	EQ.ASML	757.3685	1.77008056640625	0.23426206963401852	yfinance_direct
6181	2025-06-20	EQ.ASML	752.2872	-5.081298828125	-0.6709149674188953	yfinance_direct
6182	2025-06-23	EQ.ASML	775.347	23.05975341796875	3.065285765074836	yfinance_direct
6183	2025-06-24	EQ.ASML	808.7984	33.451416015625	4.314380099320767	yfinance_direct
6184	2025-06-25	EQ.ASML	810.6678	1.86944580078125	0.23113866184079468	yfinance_direct
6185	2025-06-26	EQ.ASML	793.6141	-17.0537109375	-2.1036619384064816	yfinance_direct
6186	2025-06-27	EQ.ASML	791.4861	-2.12799072265625	-0.26813921612751446	yfinance_direct
6187	2025-06-30	EQ.ASML	796.8956	5.409423828125	0.6834514870745481	yfinance_direct
6188	2025-07-01	EQ.ASML	786.0367	-10.85882568359375	-1.362640991880035	yfinance_direct
6189	2025-07-02	EQ.ASML	795.1057	9.06890869140625	1.1537512425819738	yfinance_direct
6190	2025-07-03	EQ.ASML	790.0443	-5.0614013671875	-0.6365696628336308	yfinance_direct
6191	2025-07-07	EQ.ASML	780.687	-9.35723876953125	-1.1843942619350847	yfinance_direct
6192	2025-07-08	EQ.ASML	789.6464	8.9593505859375	1.1476238814595767	yfinance_direct
6193	2025-07-09	EQ.ASML	795.3443	5.69793701171875	0.7215808599546468	yfinance_direct
6194	2025-07-10	EQ.ASML	797.5917	2.24737548828125	0.2825663665676432	yfinance_direct
6195	2025-07-11	EQ.ASML	797.4326	-0.15911865234375	-0.019949888817823308	yfinance_direct
6196	2025-07-14	EQ.ASML	802.2056	4.7730712890625	0.5985548561113222	yfinance_direct
6197	2025-07-15	EQ.ASML	818.4042	16.1986083984375	2.0192588837979275	yfinance_direct
6198	2025-07-16	EQ.ASML	750.2188	-68.1854248046875	-8.331509273619025	yfinance_direct
6199	2025-07-17	EQ.ASML	740.7322	-9.486572265625	-1.2645073845236396	yfinance_direct
6200	2025-07-18	EQ.ASML	730.4603	-10.27197265625	-1.386732225036311	yfinance_direct
6201	2025-07-21	EQ.ASML	715.6438	-14.81646728515625	-2.028374159760044	yfinance_direct
6202	2025-07-22	EQ.ASML	701.5234	-14.120361328125	-1.9730990964006472	yfinance_direct
6203	2025-07-23	EQ.ASML	712.9092	11.38580322265625	1.6230110947157415	yfinance_direct
6204	2025-07-24	EQ.ASML	721.0135	8.10430908203125	1.1367939450211275	yfinance_direct
6205	2025-07-25	EQ.ASML	707.2611	-13.75244140625	-1.9073762774604366	yfinance_direct
6206	2025-07-28	EQ.ASML	725.896	18.6348876953125	2.6347960426539507	yfinance_direct
6207	2025-07-29	EQ.ASML	716.2728	-9.62322998046875	-1.325703686513502	yfinance_direct
6208	2025-07-30	EQ.ASML	719.2236	2.95086669921875	0.4119752751777888	yfinance_direct
6209	2025-07-31	EQ.ASML	692.5662	-26.657470703125	-3.7064230771841924	yfinance_direct
6210	2025-08-01	EQ.ASML	687.6913	-4.8748779296875	-0.7038862416898769	yfinance_direct
6211	2025-08-04	EQ.ASML	697.2018	9.510498046875	1.3829603872644098	yfinance_direct
6212	2025-08-05	EQ.ASML	687.5018	-9.699951171875	-1.3912688434182612	yfinance_direct
6213	2025-08-06	EQ.ASML	688.8278	1.325927734375	0.1928617022504379	yfinance_direct
6214	2025-08-07	EQ.ASML	710.9194	22.09161376953125	3.2071317521186447	yfinance_direct
6215	2025-08-08	EQ.ASML	720.0909	9.17156982421875	1.2900998591739505	yfinance_direct
6216	2025-08-11	EQ.ASML	719.084	-1.00689697265625	-0.1398291400978304	yfinance_direct
6217	2025-08-12	EQ.ASML	739.5009	20.41680908203125	2.8392799440273726	yfinance_direct
6218	2025-08-13	EQ.ASML	753.2383	13.73748779296875	1.8576703068723608	yfinance_direct
6219	2025-08-14	EQ.ASML	752.8795	-0.35888671875	-0.04764583779168997	yfinance_direct
6220	2025-08-15	EQ.ASML	739.8697	-13.009765625	-1.7280011466394036	yfinance_direct
6221	2025-08-18	EQ.ASML	745.2431	5.3734130859375	0.7262647948671942	yfinance_direct
6222	2025-08-19	EQ.ASML	741.3152	-3.9278564453125	-0.5270570676007159	yfinance_direct
6223	2025-08-20	EQ.ASML	747.1771	5.86181640625	0.7907319366864463	yfinance_direct
6224	2025-08-21	EQ.ASML	733.1306	-14.04644775390625	-1.8799356203104638	yfinance_direct
6225	2025-08-22	EQ.ASML	752.5605	19.42987060546875	2.6502604313226237	yfinance_direct
6226	2025-08-25	EQ.ASML	752.1318	-0.4287109375	-0.0569669741591025	yfinance_direct
6227	2025-08-26	EQ.ASML	760.8448	8.71307373046875	1.1584504233450381	yfinance_direct
6228	2025-08-27	EQ.ASML	767.6238	6.7789306640625	0.8909741159769679	yfinance_direct
6229	2025-08-28	EQ.ASML	761.104	-6.519775390625	-0.8493451566334954	yfinance_direct
6230	2025-08-29	EQ.ASML	740.3283	-20.77569580078125	-2.729678952436614	yfinance_direct
6231	2025-09-02	EQ.ASML	723.61	-16.71832275390625	-2.2582309187513228	yfinance_direct
6232	2025-09-03	EQ.ASML	734.5462	10.93621826171875	1.5113415352339894	yfinance_direct
6233	2025-09-04	EQ.ASML	751.1049	16.5587158203125	2.2542783202552927	yfinance_direct
6234	2025-09-05	EQ.ASML	779.2877	28.18280029296875	3.7521788985513935	yfinance_direct
6235	2025-09-08	EQ.ASML	793.7928	14.505126953125	1.8613313909546243	yfinance_direct
6236	2025-09-09	EQ.ASML	802.6454	8.8525390625	1.1152203121417381	yfinance_direct
6237	2025-09-10	EQ.ASML	790.6924	-11.95294189453125	-1.4891933731704747	yfinance_direct
6238	2025-09-11	EQ.ASML	801.6783	10.98590087890625	1.3894025375336605	yfinance_direct
6239	2025-09-12	EQ.ASML	811.3584	9.6800537109375	1.2074735178532465	yfinance_direct
6240	2025-09-15	EQ.ASML	864.6235	53.26513671875	6.564933181356979	yfinance_direct
6241	2025-09-16	EQ.ASML	875.7092	11.08563232421875	1.2821340009227733	yfinance_direct
6242	2025-09-17	EQ.ASML	869.5782	-6.13092041015625	-0.7001091958184839	yfinance_direct
6243	2025-09-18	EQ.ASML	924.9368	55.35858154296875	6.366141486344306	yfinance_direct
6244	2025-09-19	EQ.ASML	929.2734	4.33660888671875	0.468854602018653	yfinance_direct
6245	2025-09-22	EQ.ASML	954.8442	25.57080078125	2.7516982353485164	yfinance_direct
6246	2025-09-23	EQ.ASML	960.5366	5.6923828125	0.5961582616601918	yfinance_direct
6247	2025-09-24	EQ.ASML	944.0178	-16.51885986328125	-1.7197532608877992	yfinance_direct
6248	2025-09-25	EQ.ASML	946.6197	2.6019287109375	0.2756228556066622	yfinance_direct
6249	2025-09-26	EQ.ASML	948.5837	1.9639892578125	0.20747394953659445	yfinance_direct
6250	2025-09-29	EQ.ASML	959.6394	11.05572509765625	1.1654981358090981	yfinance_direct
6251	2025-09-30	EQ.ASML	965.1025	5.463134765625	0.5692903752350419	yfinance_direct
6252	2025-10-01	EQ.ASML	1000.174	35.07147216796875	3.633963309436234	yfinance_direct
6253	2025-10-02	EQ.ASML	1026.991	26.81695556640625	2.6812289926844395	yfinance_direct
6254	2025-10-03	EQ.ASML	1029.0345	2.0435791015625	0.19898705710492315	yfinance_direct
6255	2025-10-06	EQ.ASML	1040.0804	11.0458984375	1.0734234804387408	yfinance_direct
6256	2025-10-07	EQ.ASML	999.207	-40.87347412109375	-3.9298377681920873	yfinance_direct
6257	2025-10-08	EQ.ASML	984.7617	-14.4453125	-1.4456777154881186	yfinance_direct
6258	2025-10-09	EQ.ASML	977.514	-7.24761962890625	-0.7359770328309162	yfinance_direct
6259	2025-10-10	EQ.ASML	933.301	-44.21307373046875	-4.523011640532756	yfinance_direct
6260	2025-10-13	EQ.ASML	981.6214	48.3204345703125	5.177368974828207	yfinance_direct
6261	2025-10-14	EQ.ASML	980.1459	-1.4754638671875	-0.1503088531690676	yfinance_direct
6262	2025-10-15	EQ.ASML	1006.6938	26.5478515625	2.708561104312793	yfinance_direct
6263	2025-10-16	EQ.ASML	1016.4436	9.74981689453125	0.9684987653749126	yfinance_direct
6264	2025-10-17	EQ.ASML	1026.0938	9.650146484375	0.9494030412506458	yfinance_direct
6265	2025-10-20	EQ.ASML	1038.934	12.8402099609375	1.251368109486828	yfinance_direct
6266	2025-10-21	EQ.ASML	1021.8568	-17.0771484375	-1.643718378225126	yfinance_direct
6267	2025-10-22	EQ.ASML	1008.4484	-13.408447265625	-1.312164983823417	yfinance_direct
6268	2025-10-23	EQ.ASML	1033.2117	24.7633056640625	2.455584890782935	yfinance_direct
6269	2025-10-24	EQ.ASML	1029.9119	-3.2998046875	-0.3193735401526689	yfinance_direct
6270	2025-10-27	EQ.ASML	1056.7089	26.7969970703125	2.6018728373630653	yfinance_direct
6271	2025-10-28	EQ.ASML	1049.2321	-7.476806640625	-0.7075559699876128	yfinance_direct
6272	2025-10-29	EQ.ASML	1069.4294	20.1973876953125	1.9249686078766919	yfinance_direct
6273	2025-10-30	EQ.ASML	1074.0333	4.6038818359375	0.43049888559972954	yfinance_direct
6274	2025-10-31	EQ.ASML	1057.8347	-16.1986083984375	-1.508203518311854	yfinance_direct
6275	2025-11-03	EQ.ASML	1065.4147	7.5799560546875	0.7165539128494116	yfinance_direct
6276	2025-11-04	EQ.ASML	1028.7831	-36.631591796875	-3.438247353852489	yfinance_direct
6277	2025-11-05	EQ.ASML	1042.3751	13.592041015625	1.3211765692813218	yfinance_direct
6278	2025-11-06	EQ.ASML	1027.8442	-14.5308837890625	-1.3940167489993427	yfinance_direct
6279	2025-11-07	EQ.ASML	1015.6204	-12.22381591796875	-1.1892673483687841	yfinance_direct
6280	2025-11-10	EQ.ASML	1037.4216	21.80120849609375	2.1465902039822895	yfinance_direct
6281	2025-11-11	EQ.ASML	1021.0732	-16.34844970703125	-1.575873224610575	yfinance_direct
6282	2025-11-12	EQ.ASML	1035.9635	14.89031982421875	1.458300942486229	yfinance_direct
6283	2025-11-13	EQ.ASML	1018.5165	-17.44696044921875	-1.6841288744991671	yfinance_direct
6284	2025-11-14	EQ.ASML	1005.6535	-12.863037109375	-1.2629188233619728	yfinance_direct
6285	2025-11-17	EQ.ASML	1018.6564	13.00286865234375	1.2929770152592517	yfinance_direct
6286	2025-11-18	EQ.ASML	1002.7374	-15.91900634765625	-1.5627454737560356	yfinance_direct
6287	2025-11-19	EQ.ASML	1037.9609	35.22357177734375	3.512741519506327	yfinance_direct
6288	2025-11-20	EQ.ASML	979.7477	-58.2132568359375	-5.608424626860055	yfinance_direct
6289	2025-11-21	EQ.ASML	965.2968	-14.450927734375	-1.4749642198265083	yfinance_direct
6290	2025-11-24	EQ.ASML	986.5188	21.2220458984375	2.1984996669706316	yfinance_direct
6291	2025-11-25	EQ.ASML	1001.8984	15.379638671875	1.5589808009887198	yfinance_direct
6292	2025-11-26	EQ.ASML	1039.5988	37.7003173828125	3.7628881303462958	yfinance_direct
6293	2025-11-28	EQ.ASML	1058.6038	19.0050048828125	1.82810962340512	yfinance_direct
6294	2025-12-01	EQ.ASML	1086.5568	27.9530029296875	2.6405539062015326	yfinance_direct
6295	2025-12-02	EQ.ASML	1107.3195	20.7626953125	1.9108707455831448	yfinance_direct
6296	2025-12-03	EQ.ASML	1139.4171	32.09765625	2.898680775261292	yfinance_direct
6297	2025-12-04	EQ.ASML	1108.6177	-30.7994384765625	-2.703087226895348	yfinance_direct
6298	2025-12-05	EQ.ASML	1098.0217	-10.595947265625	-0.9557801122156895	yfinance_direct
6299	2025-12-08	EQ.ASML	1118.215	20.1932373046875	1.8390562572915556	yfinance_direct
6300	2025-12-09	EQ.ASML	1109.9758	-8.2391357421875	-0.7368114355492769	yfinance_direct
6301	2025-12-10	EQ.ASML	1117.8455	7.86962890625	0.7089910152094123	yfinance_direct
6302	2025-12-11	EQ.ASML	1121.3608	3.515380859375	0.3144782519910149	yfinance_direct
6303	2025-12-12	EQ.ASML	1079.4263	-41.9345703125	-3.7396142992065915	yfinance_direct
6304	2025-12-15	EQ.ASML	1086.387	6.960693359375	0.6448512099300436	yfinance_direct
6305	2025-12-16	EQ.ASML	1074.6326	-11.75439453125	-1.0819712434669013	yfinance_direct
6306	2025-12-17	EQ.ASML	1014.0924	-60.5401611328125	-5.633568432160793	yfinance_direct
6307	2025-12-18	EQ.ASML	1034.9449	20.8525390625	2.056276027105807	yfinance_direct
6308	2025-12-19	EQ.ASML	1054.6289	19.6839599609375	1.9019330478898464	yfinance_direct
6309	2025-12-22	EQ.ASML	1055.5876	0.958740234375	0.09090782821267848	yfinance_direct
6310	2025-12-23	EQ.ASML	1060.4413	4.8536376953125	0.4598043290367689	yfinance_direct
6311	2025-12-24	EQ.ASML	1064.1165	3.6751708984375	0.34656995660824885	yfinance_direct
6312	2025-12-26	EQ.ASML	1071.3369	7.220458984375	0.6785402997874787	yfinance_direct
6313	2025-12-29	EQ.ASML	1064.5958	-6.7410888671875	-0.6292221222570733	yfinance_direct
6314	2025-12-30	EQ.ASML	1070.7278	6.1319580078125	0.5759892968477047	yfinance_direct
6315	2025-12-31	EQ.ASML	1068.4507	-2.277099609375	-0.2126683966827652	yfinance_direct
6316	2026-01-02	EQ.ASML	1162.2471	93.79638671875	8.77872869183484	yfinance_direct
6317	2026-01-05	EQ.ASML	1226.5721	64.3250732421875	5.534543806154061	yfinance_direct
6318	2026-01-06	EQ.ASML	1240.5537	13.9815673828125	1.1398895251520216	yfinance_direct
6319	2026-01-07	EQ.ASML	1226.8518	-13.701904296875	-1.1044990777965045	yfinance_direct
6320	2026-01-08	EQ.ASML	1192.7467	-34.1051025390625	-2.779887705626758	yfinance_direct
6321	2026-01-09	EQ.ASML	1272.202	79.455322265625	6.661541967996867	yfinance_direct
6322	2026-01-12	EQ.ASML	1279.5422	7.3402099609375	0.5769688939969463	yfinance_direct
6323	2026-01-13	EQ.ASML	1268.4869	-11.0552978515625	-0.8640041366112033	yfinance_direct
6324	2026-01-14	EQ.ASML	1262.0553	-6.431640625	-0.5070324675730854	yfinance_direct
6325	2026-01-15	EQ.ASML	1329.8459	67.7906494140625	5.371448424602686	yfinance_direct
6326	2026-01-16	EQ.ASML	1356.7804	26.9344482421875	2.0253810824907212	yfinance_direct
6327	2026-01-20	EQ.ASML	1324.3231	-32.457275390625	-2.392227621956239	yfinance_direct
6328	2026-01-21	EQ.ASML	1358.2983	33.9752197265625	2.565478108058408	yfinance_direct
6329	2026-01-22	EQ.ASML	1393.1625	34.8641357421875	2.5667509647547715	yfinance_direct
6330	2026-01-23	EQ.ASML	1387.2103	-5.9521484375	-0.4272400772922512	yfinance_direct
6331	2026-01-26	EQ.ASML	1411.4883	24.2779541015625	1.7501278376054545	yfinance_direct
6332	2026-01-27	EQ.ASML	1452.6738	41.185546875	2.917880893671075	yfinance_direct
6333	2026-01-28	EQ.ASML	1421.0457	-31.628173828125	-2.1772384974367043	yfinance_direct
6334	2026-01-29	EQ.ASML	1453.2432	32.197509765625	2.2657618119634684	yfinance_direct
6335	2026-01-30	EQ.ASML	1421.1255	-32.11767578125	-2.210068939286523	yfinance_direct
6336	2026-02-02	EQ.ASML	1439.4913	18.3658447265625	1.2923450376486232	yfinance_direct
6337	2026-02-03	EQ.ASML	1394.0413	-45.4500732421875	-3.157370398835241	yfinance_direct
6338	2026-02-04	EQ.ASML	1337.366	-56.67529296875	-4.065539134636417	yfinance_direct
6339	2026-02-05	EQ.ASML	1348.3815	11.0155029296875	0.8236715456481017	yfinance_direct
6340	2026-02-06	EQ.ASML	1411.1487	62.7672119140625	4.655004041756153	yfinance_direct
6341	2026-02-09	EQ.ASML	1427.6069	16.458251953125	1.166301763042457	yfinance_direct
6342	2026-02-10	EQ.ASML	1413.62	-13.9869384765625	-0.9797471662142209	yfinance_direct
6343	2026-02-11	EQ.ASML	1435.63	22.010009765625	1.5569962112625886	yfinance_direct
6344	2026-02-12	EQ.ASML	1406.87	-28.760009765625	-2.0033023597868183	yfinance_direct
6345	2026-02-13	EQ.ASML	1406.61	-0.260009765625	-0.018481435138101875	yfinance_direct
6346	2026-02-17	EQ.ASML	1419.78	13.1700439453125	0.9362967761117401	yfinance_direct
6347	2026-02-18	EQ.ASML	1468.72	48.93994140625	3.4470087194061168	yfinance_direct
6348	2026-02-19	EQ.ASML	1458.9301	-9.7899169921875	-0.6665611680557963	yfinance_direct
6349	2026-02-20	EQ.ASML	1469.59	10.659912109375	0.7306664279250692	yfinance_direct
6350	2026-02-23	EQ.ASML	1485.99	16.4000244140625	1.1159591991979985	yfinance_direct
6351	2026-02-24	EQ.ASML	1497.8	11.81005859375	0.7947603060157411	yfinance_direct
6352	2026-02-25	EQ.ASML	1526.51	28.7099609375	1.9168086527946504	yfinance_direct
6353	2026-02-26	EQ.ASML	1463.8	-62.7099609375	-4.108060906009275	yfinance_direct
6354	2026-02-27	EQ.ASML	1450.5601	-13.239990234375	-0.9044944522972618	yfinance_direct
6355	2026-03-02	EQ.ASML	1423.54	-27.02001953125	-1.8627301483431609	yfinance_direct
6356	2026-03-03	EQ.ASML	1360.9399	-62.60009765625	-4.397494691998724	yfinance_direct
6357	2026-03-04	EQ.ASML	1399.37	38.4300537109375	2.8237876295428577	yfinance_direct
6358	2026-03-05	EQ.ASML	1368.36	-31.010009765625	-2.215997904330379	yfinance_direct
6359	2026-03-06	EQ.ASML	1292.8	-75.5599365234375	-5.521934091343986	yfinance_direct
6360	2026-03-09	EQ.ASML	1357.42	64.6199951171875	4.998452403816284	yfinance_direct
6361	2026-03-10	EQ.ASML	1383.4	25.97998046875	1.9139234450406184	yfinance_direct
6362	2026-03-11	EQ.ASML	1386.6801	3.280029296875	0.2370991209331699	yfinance_direct
6363	2026-03-12	EQ.ASML	1351.58	-35.10009765625	-2.5312326056985923	yfinance_direct
6364	2026-03-13	EQ.ASML	1345.6899	-5.8900146484375	-0.4357873629341673	yfinance_direct
6365	2026-03-16	EQ.ASML	1375.5601	29.8701171875	2.219687928727894	yfinance_direct
6366	2026-03-17	EQ.ASML	1389.16	13.5999755859375	0.9886864263739166	yfinance_direct
6367	2026-03-18	EQ.ASML	1355.17	-33.989990234375	-2.446801620984325	yfinance_direct
\.


--
-- Data for Name: pipeline_errors; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pipeline_errors (id, source_id, error_type, error_msg, "timestamp") FROM stdin;
1	ecb_speeches_rss	fetch_error	404 Client Error: Not Found for url: https://www.ecb.europa.eu/rss/speeches.rss	2026-03-09 18:01:13.767919+00
2	bis_papers_rss	fetch_error	404 Client Error: Not Found for url: https://www.bis.org/doclist/bis_fsi_speeches.rss	2026-03-09 18:01:13.767919+00
3	reuters_markets_rss	fetch_error	HTTPSConnectionPool(host='feeds.reuters.com', port=443): Max retries exceeded with url: /reuters/businessNews (Caused by NameResolutionError("<urllib3.connection.HTTPSConnection object at 0x105d57cb0>: Failed to resolve 'feeds.reuters.com' ([Errno 8] nodename nor servname provided, or not known)"))	2026-03-09 18:01:13.767919+00
4	fred_macro_series	config_error	FRED_API_KEY missing or empty	2026-03-09 18:01:13.767919+00
5	ecb_sdw_series	fetch_error	series IRS.M.DE.L.L40.CI.0.EUR.2Y.NX: 404 Client Error:  for url: https://data-api.ecb.europa.eu/service/data/IRS/M.DE.L.L40.CI.0.EUR.2Y.NX?startPeriod=2025-03-09&endPeriod=2026-03-09&format=jsondata&detail=dataonly	2026-03-09 18:01:13.767919+00
6	ecb_sdw_series	fetch_error	series IRS.M.IT.L.L40.CI.0.EUR.10Y.NX: 404 Client Error:  for url: https://data-api.ecb.europa.eu/service/data/IRS/M.IT.L.L40.CI.0.EUR.10Y.NX?startPeriod=2025-03-09&endPeriod=2026-03-09&format=jsondata&detail=dataonly	2026-03-09 18:01:13.767919+00
7	cftc_cot_weekly	empty_result	Parsed 0 CoT rows from ZIP	2026-03-09 18:01:13.767919+00
8	ecb_press_releases_scrape	fetch_error	404 Client Error: Not Found for url: https://www.ecb.europa.eu/press/pr/date/2025/html/index.en.html	2026-03-09 18:01:13.767919+00
9	ecb_speeches_rss	fetch_error	404 Client Error: Not Found for url: https://www.ecb.europa.eu/rss/speeches.rss	2026-03-09 18:02:22.593695+00
10	bis_papers_rss	fetch_error	404 Client Error: Not Found for url: https://www.bis.org/doclist/bis_fsi_speeches.rss	2026-03-09 18:02:22.593695+00
11	reuters_markets_rss	fetch_error	HTTPSConnectionPool(host='feeds.reuters.com', port=443): Max retries exceeded with url: /reuters/businessNews (Caused by NameResolutionError("<urllib3.connection.HTTPSConnection object at 0x105492f90>: Failed to resolve 'feeds.reuters.com' ([Errno 8] nodename nor servname provided, or not known)"))	2026-03-09 18:02:22.593695+00
12	fred_macro_series	config_error	FRED_API_KEY missing or empty	2026-03-09 18:02:22.593695+00
13	ecb_sdw_series	fetch_error	series IRS.M.DE.L.L40.CI.0.EUR.2Y.NX: 404 Client Error:  for url: https://data-api.ecb.europa.eu/service/data/IRS/M.DE.L.L40.CI.0.EUR.2Y.NX?startPeriod=2025-03-09&endPeriod=2026-03-09&format=jsondata&detail=dataonly	2026-03-09 18:02:22.593695+00
14	ecb_sdw_series	fetch_error	series IRS.M.IT.L.L40.CI.0.EUR.10Y.NX: 404 Client Error:  for url: https://data-api.ecb.europa.eu/service/data/IRS/M.IT.L.L40.CI.0.EUR.10Y.NX?startPeriod=2025-03-09&endPeriod=2026-03-09&format=jsondata&detail=dataonly	2026-03-09 18:02:22.593695+00
15	cftc_cot_weekly	empty_result	Parsed 0 CoT rows from ZIP	2026-03-09 18:02:22.593695+00
16	ecb_press_releases_scrape	fetch_error	404 Client Error: Not Found for url: https://www.ecb.europa.eu/press/pr/date/2026/html/index.en.html	2026-03-09 18:02:22.593695+00
17	ecb_speeches_rss	fetch_error	404 Client Error: Not Found for url: https://www.ecb.europa.eu/rss/speeches.rss	2026-03-09 18:11:31.66825+00
18	bis_papers_rss	fetch_error	404 Client Error: Not Found for url: https://www.bis.org/doclist/wppdf.rss	2026-03-09 18:11:31.66825+00
19	ecb_sdw_series	fetch_error	series IRS.M.DE.L.L40.CI.0.EUR.2Y.NX: 404 Client Error:  for url: https://data-api.ecb.europa.eu/service/data/IRS/M.DE.L.L40.CI.0.EUR.2Y.NX?startPeriod=2025-03-09&endPeriod=2026-03-09&format=jsondata&detail=dataonly	2026-03-09 18:11:31.66825+00
20	ecb_sdw_series	fetch_error	series IRS.M.IT.L.L40.CI.0.EUR.10Y.NX: 404 Client Error:  for url: https://data-api.ecb.europa.eu/service/data/IRS/M.IT.L.L40.CI.0.EUR.10Y.NX?startPeriod=2025-03-09&endPeriod=2026-03-09&format=jsondata&detail=dataonly	2026-03-09 18:11:31.66825+00
21	cftc_cot_weekly	empty_result	Parsed 0 CoT rows from ZIP	2026-03-09 18:11:31.66825+00
22	ecb_press_releases_scrape	fetch_error	404 Client Error: Not Found for url: https://www.ecb.europa.eu/press/pr/date/2026/html/index.en.html	2026-03-09 18:11:31.66825+00
23	ecb_speeches_rss	fetch_error	404 Client Error: Not Found for url: https://www.ecb.europa.eu/rss/press.rss	2026-03-09 18:12:17.742036+00
24	ecb_sdw_series	fetch_error	series IRS.M.DE.L.L40.CI.0.EUR.2Y.NX: 404 Client Error:  for url: https://data-api.ecb.europa.eu/service/data/IRS/M.DE.L.L40.CI.0.EUR.2Y.NX?startPeriod=2025-03-09&endPeriod=2026-03-09&format=jsondata&detail=dataonly	2026-03-09 18:12:17.742036+00
25	ecb_sdw_series	fetch_error	series IRS.M.IT.L.L40.CI.0.EUR.10Y.NX: 404 Client Error:  for url: https://data-api.ecb.europa.eu/service/data/IRS/M.IT.L.L40.CI.0.EUR.10Y.NX?startPeriod=2025-03-09&endPeriod=2026-03-09&format=jsondata&detail=dataonly	2026-03-09 18:12:17.742036+00
26	cftc_cot_weekly	empty_result	Parsed 0 CoT rows from ZIP	2026-03-09 18:12:17.742036+00
27	ecb_press_releases_scrape	fetch_error	404 Client Error: Not Found for url: https://www.ecb.europa.eu/press/pr/date/2026/html/index.en.html	2026-03-09 18:12:17.742036+00
28	ecb_speeches_rss	fetch_error	404 Client Error: Not Found for url: https://www.ecb.europa.eu/rss/press.rss	2026-03-09 18:13:19.356245+00
29	ecb_sdw_series	fetch_error	series IRS.M.DE.L.L40.CI.0.EUR.2Y.NX: 404 Client Error:  for url: https://data-api.ecb.europa.eu/service/data/IRS/M.DE.L.L40.CI.0.EUR.2Y.NX?startPeriod=2025-03-09&endPeriod=2026-03-09&format=jsondata&detail=dataonly	2026-03-09 18:13:19.356245+00
30	ecb_sdw_series	fetch_error	series IRS.M.IT.L.L40.CI.0.EUR.10Y.NX: 404 Client Error:  for url: https://data-api.ecb.europa.eu/service/data/IRS/M.IT.L.L40.CI.0.EUR.10Y.NX?startPeriod=2025-03-09&endPeriod=2026-03-09&format=jsondata&detail=dataonly	2026-03-09 18:13:19.356245+00
31	cftc_cot_weekly	empty_result	Parsed 0 CoT rows from ZIP	2026-03-09 18:13:19.356245+00
32	ecb_press_releases_scrape	fetch_error	404 Client Error: Not Found for url: https://www.ecb.europa.eu/press/pr/date/2026/html/index.en.html	2026-03-09 18:13:19.356245+00
33	ecb_speeches_rss	fetch_error	404 Client Error: Not Found for url: https://www.ecb.europa.eu/rss/press.rss	2026-03-09 18:21:04.953589+00
34	ecb_sdw_series	fetch_error	series IRS.M.DE.L.L40.CI.0.EUR.2Y.NX: 404 Client Error:  for url: https://data-api.ecb.europa.eu/service/data/IRS/M.DE.L.L40.CI.0.EUR.2Y.NX?startPeriod=2025-03-09&endPeriod=2026-03-09&format=jsondata&detail=dataonly	2026-03-09 18:21:04.953589+00
35	ecb_sdw_series	fetch_error	series IRS.M.IT.L.L40.CI.0.EUR.10Y.NX: 404 Client Error:  for url: https://data-api.ecb.europa.eu/service/data/IRS/M.IT.L.L40.CI.0.EUR.10Y.NX?startPeriod=2025-03-09&endPeriod=2026-03-09&format=jsondata&detail=dataonly	2026-03-09 18:21:04.953589+00
36	cftc_cot_weekly	empty_result	Parsed 0 CoT rows from ZIP	2026-03-09 18:21:04.953589+00
37	ecb_press_releases_scrape	fetch_error	404 Client Error: Not Found for url: https://www.ecb.europa.eu/press/pr/date/2026/html/index.en.html	2026-03-09 18:21:04.953589+00
38	ecb_speeches_rss	fetch_error	404 Client Error: Not Found for url: https://www.ecb.europa.eu/rss/press.rss	2026-03-09 18:23:26.426616+00
39	ecb_sdw_series	fetch_error	series IRS.M.DE.L.L40.CI.0.EUR.2Y.NX: 404 Client Error:  for url: https://data-api.ecb.europa.eu/service/data/IRS/M.DE.L.L40.CI.0.EUR.2Y.NX?startPeriod=2025-03-09&endPeriod=2026-03-09&format=jsondata&detail=dataonly	2026-03-09 18:23:26.426616+00
40	ecb_sdw_series	fetch_error	series IRS.M.IT.L.L40.CI.0.EUR.10Y.NX: 404 Client Error:  for url: https://data-api.ecb.europa.eu/service/data/IRS/M.IT.L.L40.CI.0.EUR.10Y.NX?startPeriod=2025-03-09&endPeriod=2026-03-09&format=jsondata&detail=dataonly	2026-03-09 18:23:26.426616+00
41	cftc_cot_weekly	empty_result	Parsed 0 CoT rows from ZIP	2026-03-09 18:23:26.426616+00
42	ecb_press_releases_scrape	fetch_error	404 Client Error: Not Found for url: https://www.ecb.europa.eu/press/pr/date/2026/html/index.en.html	2026-03-09 18:23:26.426616+00
43	ecb_speeches_rss	fetch_error	404 Client Error: Not Found for url: https://www.ecb.europa.eu/rss/press.rss	2026-03-09 18:23:40.524969+00
44	ecb_sdw_series	fetch_error	series IRS.M.DE.L.L40.CI.0.EUR.2Y.NX: 404 Client Error:  for url: https://data-api.ecb.europa.eu/service/data/IRS/M.DE.L.L40.CI.0.EUR.2Y.NX?startPeriod=2025-03-09&endPeriod=2026-03-09&format=jsondata&detail=dataonly	2026-03-09 18:23:40.524969+00
45	ecb_sdw_series	fetch_error	series IRS.M.IT.L.L40.CI.0.EUR.10Y.NX: 404 Client Error:  for url: https://data-api.ecb.europa.eu/service/data/IRS/M.IT.L.L40.CI.0.EUR.10Y.NX?startPeriod=2025-03-09&endPeriod=2026-03-09&format=jsondata&detail=dataonly	2026-03-09 18:23:40.524969+00
46	cftc_cot_weekly	empty_result	Parsed 0 CoT rows from ZIP	2026-03-09 18:23:40.524969+00
47	ecb_press_releases_scrape	fetch_error	404 Client Error: Not Found for url: https://www.ecb.europa.eu/press/pr/date/2026/html/index.en.html	2026-03-09 18:23:40.524969+00
48	ecb_speeches_rss	fetch_error	404 Client Error: Not Found for url: https://www.ecb.europa.eu/rss/press.rss	2026-03-09 18:26:20.349481+00
49	ecb_sdw_series	fetch_error	series IRS.M.DE.L.L40.CI.0.EUR.2Y.NX: 404 Client Error:  for url: https://data-api.ecb.europa.eu/service/data/IRS/M.DE.L.L40.CI.0.EUR.2Y.NX?startPeriod=2025-03-09&endPeriod=2026-03-09&format=jsondata&detail=dataonly	2026-03-09 18:26:20.349481+00
50	ecb_sdw_series	fetch_error	series IRS.M.IT.L.L40.CI.0.EUR.10Y.NX: 404 Client Error:  for url: https://data-api.ecb.europa.eu/service/data/IRS/M.IT.L.L40.CI.0.EUR.10Y.NX?startPeriod=2025-03-09&endPeriod=2026-03-09&format=jsondata&detail=dataonly	2026-03-09 18:26:20.349481+00
51	cftc_cot_weekly	empty_result	Parsed 0 CoT rows from ZIP	2026-03-09 18:26:20.349481+00
52	ecb_press_releases_scrape	fetch_error	404 Client Error: Not Found for url: https://www.ecb.europa.eu/press/pr/date/2026/html/index.en.html	2026-03-09 18:26:20.349481+00
53	ecb_speeches_rss	fetch_error	404 Client Error: Not Found for url: https://www.ecb.europa.eu/rss/press.rss	2026-03-09 18:27:53.287104+00
54	ecb_sdw_series	fetch_error	series IRS.M.DE.L.L40.CI.0.EUR.2Y.NX: 404 Client Error:  for url: https://data-api.ecb.europa.eu/service/data/IRS/M.DE.L.L40.CI.0.EUR.2Y.NX?startPeriod=2025-03-09&endPeriod=2026-03-09&format=jsondata&detail=dataonly	2026-03-09 18:27:53.287104+00
55	ecb_sdw_series	fetch_error	series IRS.M.IT.L.L40.CI.0.EUR.10Y.NX: 404 Client Error:  for url: https://data-api.ecb.europa.eu/service/data/IRS/M.IT.L.L40.CI.0.EUR.10Y.NX?startPeriod=2025-03-09&endPeriod=2026-03-09&format=jsondata&detail=dataonly	2026-03-09 18:27:53.287104+00
56	cftc_cot_weekly	empty_result	Parsed 0 CoT rows from ZIP	2026-03-09 18:27:53.287104+00
57	ecb_press_releases_scrape	fetch_error	404 Client Error: Not Found for url: https://www.ecb.europa.eu/press/pr/date/2026/html/index.en.html	2026-03-09 18:27:53.287104+00
58	ecb_speeches_rss	fetch_error	404 Client Error: Not Found for url: https://www.ecb.europa.eu/rss/press.rss	2026-03-09 18:34:01.261281+00
59	ecb_sdw_series	fetch_error	series IRS.M.DE.L.L40.CI.0.EUR.2Y.NX: 404 Client Error:  for url: https://data-api.ecb.europa.eu/service/data/IRS/M.DE.L.L40.CI.0.EUR.2Y.NX?startPeriod=2025-03-09&endPeriod=2026-03-09&format=jsondata&detail=dataonly	2026-03-09 18:34:01.261281+00
60	ecb_sdw_series	fetch_error	series IRS.M.IT.L.L40.CI.0.EUR.10Y.NX: 404 Client Error:  for url: https://data-api.ecb.europa.eu/service/data/IRS/M.IT.L.L40.CI.0.EUR.10Y.NX?startPeriod=2025-03-09&endPeriod=2026-03-09&format=jsondata&detail=dataonly	2026-03-09 18:34:01.261281+00
61	cftc_cot_weekly	empty_result	Parsed 0 CoT rows from ZIP	2026-03-09 18:34:01.261281+00
62	ecb_press_releases_scrape	fetch_error	404 Client Error: Not Found for url: https://www.ecb.europa.eu/press/pr/date/2026/html/index.en.html	2026-03-09 18:34:01.261281+00
63	ecb_speeches_rss	fetch_error	404 Client Error: Not Found for url: https://www.ecb.europa.eu/rss/press.rss	2026-03-09 18:40:39.545655+00
64	ecb_sdw_series	fetch_error	series IRS.M.DE.L.L40.CI.0.EUR.2Y.NX: 404 Client Error:  for url: https://data-api.ecb.europa.eu/service/data/IRS/M.DE.L.L40.CI.0.EUR.2Y.NX?startPeriod=2025-03-09&endPeriod=2026-03-09&format=jsondata&detail=dataonly	2026-03-09 18:40:39.545655+00
65	ecb_sdw_series	fetch_error	series IRS.M.IT.L.L40.CI.0.EUR.10Y.NX: 404 Client Error:  for url: https://data-api.ecb.europa.eu/service/data/IRS/M.IT.L.L40.CI.0.EUR.10Y.NX?startPeriod=2025-03-09&endPeriod=2026-03-09&format=jsondata&detail=dataonly	2026-03-09 18:40:39.545655+00
66	cftc_cot_weekly	empty_result	Parsed 0 CoT rows from ZIP	2026-03-09 18:40:39.545655+00
67	ecb_press_releases_scrape	fetch_error	404 Client Error: Not Found for url: https://www.ecb.europa.eu/press/pr/date/2026/html/index.en.html	2026-03-09 18:40:39.545655+00
68	ecb_speeches_rss	fetch_error	404 Client Error: Not Found for url: https://www.ecb.europa.eu/rss/press.rss	2026-03-09 18:41:47.284401+00
69	ecb_sdw_series	fetch_error	series IRS.M.DE.L.L40.CI.0.EUR.2Y.NX: 404 Client Error:  for url: https://data-api.ecb.europa.eu/service/data/IRS/M.DE.L.L40.CI.0.EUR.2Y.NX?startPeriod=2025-03-09&endPeriod=2026-03-09&format=jsondata&detail=dataonly	2026-03-09 18:41:47.284401+00
70	ecb_sdw_series	fetch_error	series IRS.M.IT.L.L40.CI.0.EUR.10Y.NX: 404 Client Error:  for url: https://data-api.ecb.europa.eu/service/data/IRS/M.IT.L.L40.CI.0.EUR.10Y.NX?startPeriod=2025-03-09&endPeriod=2026-03-09&format=jsondata&detail=dataonly	2026-03-09 18:41:47.284401+00
71	cftc_cot_weekly	empty_result	Parsed 0 CoT rows from ZIP	2026-03-09 18:41:47.284401+00
72	ecb_press_releases_scrape	fetch_error	404 Client Error: Not Found for url: https://www.ecb.europa.eu/press/pr/date/2026/html/index.en.html	2026-03-09 18:41:47.284401+00
73	ecb_speeches_rss	fetch_error	404 Client Error: Not Found for url: https://www.ecb.europa.eu/rss/press.rss	2026-03-09 18:42:43.302682+00
74	ecb_sdw_series	fetch_error	series IRS.M.DE.L.L40.CI.0.EUR.2Y.NX: 404 Client Error:  for url: https://data-api.ecb.europa.eu/service/data/IRS/M.DE.L.L40.CI.0.EUR.2Y.NX?startPeriod=2025-03-09&endPeriod=2026-03-09&format=jsondata&detail=dataonly	2026-03-09 18:42:43.302682+00
75	ecb_sdw_series	fetch_error	series IRS.M.IT.L.L40.CI.0.EUR.10Y.NX: 404 Client Error:  for url: https://data-api.ecb.europa.eu/service/data/IRS/M.IT.L.L40.CI.0.EUR.10Y.NX?startPeriod=2025-03-09&endPeriod=2026-03-09&format=jsondata&detail=dataonly	2026-03-09 18:42:43.302682+00
76	cftc_cot_weekly	empty_result	Parsed 0 CoT rows from ZIP	2026-03-09 18:42:43.302682+00
77	ecb_press_releases_scrape	fetch_error	404 Client Error: Not Found for url: https://www.ecb.europa.eu/press/pr/date/2026/html/index.en.html	2026-03-09 18:42:43.302682+00
78	ecb_speeches_rss	fetch_error	404 Client Error: Not Found for url: https://www.ecb.europa.eu/rss/press.rss	2026-03-09 18:44:21.874046+00
79	ecb_sdw_series	fetch_error	series IRS.M.DE.L.L40.CI.0.EUR.2Y.NX: 404 Client Error:  for url: https://data-api.ecb.europa.eu/service/data/IRS/M.DE.L.L40.CI.0.EUR.2Y.NX?startPeriod=2025-03-09&endPeriod=2026-03-09&format=jsondata&detail=dataonly	2026-03-09 18:44:21.874046+00
80	ecb_sdw_series	fetch_error	series IRS.M.IT.L.L40.CI.0.EUR.10Y.NX: 404 Client Error:  for url: https://data-api.ecb.europa.eu/service/data/IRS/M.IT.L.L40.CI.0.EUR.10Y.NX?startPeriod=2025-03-09&endPeriod=2026-03-09&format=jsondata&detail=dataonly	2026-03-09 18:44:21.874046+00
81	cftc_cot_weekly	empty_result	Parsed 0 CoT rows from ZIP	2026-03-09 18:44:21.874046+00
82	ecb_press_releases_scrape	fetch_error	404 Client Error: Not Found for url: https://www.ecb.europa.eu/press/pr/date/2026/html/index.en.html	2026-03-09 18:44:21.874046+00
83	ecb_speeches_rss	fetch_error	404 Client Error: Not Found for url: https://www.ecb.europa.eu/rss/press.rss	2026-03-09 18:44:53.169219+00
84	ecb_sdw_series	fetch_error	series IRS.M.DE.L.L40.CI.0.EUR.2Y.NX: 404 Client Error:  for url: https://data-api.ecb.europa.eu/service/data/IRS/M.DE.L.L40.CI.0.EUR.2Y.NX?startPeriod=2025-03-09&endPeriod=2026-03-09&format=jsondata&detail=dataonly	2026-03-09 18:44:53.169219+00
85	ecb_sdw_series	fetch_error	series IRS.M.IT.L.L40.CI.0.EUR.10Y.NX: 404 Client Error:  for url: https://data-api.ecb.europa.eu/service/data/IRS/M.IT.L.L40.CI.0.EUR.10Y.NX?startPeriod=2025-03-09&endPeriod=2026-03-09&format=jsondata&detail=dataonly	2026-03-09 18:44:53.169219+00
86	cftc_cot_weekly	empty_result	Parsed 0 CoT rows from ZIP	2026-03-09 18:44:53.169219+00
87	ecb_press_releases_scrape	fetch_error	404 Client Error: Not Found for url: https://www.ecb.europa.eu/press/pr/date/2026/html/index.en.html	2026-03-09 18:44:53.169219+00
88	ecb_speeches_rss	fetch_error	404 Client Error: Not Found for url: https://www.ecb.europa.eu/rss/press.rss	2026-03-09 18:51:13.815837+00
89	ecb_sdw_series	fetch_error	series IRS.M.DE.L.L40.CI.0.EUR.2Y.NX: 404 Client Error:  for url: https://data-api.ecb.europa.eu/service/data/IRS/M.DE.L.L40.CI.0.EUR.2Y.NX?startPeriod=2025-03-09&endPeriod=2026-03-09&format=jsondata&detail=dataonly	2026-03-09 18:51:13.815837+00
90	ecb_sdw_series	fetch_error	series IRS.M.IT.L.L40.CI.0.EUR.10Y.NX: 404 Client Error:  for url: https://data-api.ecb.europa.eu/service/data/IRS/M.IT.L.L40.CI.0.EUR.10Y.NX?startPeriod=2025-03-09&endPeriod=2026-03-09&format=jsondata&detail=dataonly	2026-03-09 18:51:13.815837+00
91	cftc_cot_weekly	empty_result	Parsed 0 CoT rows from ZIP	2026-03-09 18:51:13.815837+00
92	ecb_press_releases_scrape	fetch_error	404 Client Error: Not Found for url: https://www.ecb.europa.eu/press/pr/date/2026/html/index.en.html	2026-03-09 18:51:13.815837+00
93	ecb_speeches_rss	fetch_error	404 Client Error: Not Found for url: https://www.ecb.europa.eu/rss/press.rss	2026-03-09 18:51:45.722056+00
94	ecb_sdw_series	fetch_error	series IRS.M.DE.L.L40.CI.0.EUR.2Y.NX: 404 Client Error:  for url: https://data-api.ecb.europa.eu/service/data/IRS/M.DE.L.L40.CI.0.EUR.2Y.NX?startPeriod=2025-03-09&endPeriod=2026-03-09&format=jsondata&detail=dataonly	2026-03-09 18:51:45.722056+00
95	ecb_sdw_series	fetch_error	series IRS.M.IT.L.L40.CI.0.EUR.10Y.NX: 404 Client Error:  for url: https://data-api.ecb.europa.eu/service/data/IRS/M.IT.L.L40.CI.0.EUR.10Y.NX?startPeriod=2025-03-09&endPeriod=2026-03-09&format=jsondata&detail=dataonly	2026-03-09 18:51:45.722056+00
96	cftc_cot_weekly	empty_result	Parsed 0 CoT rows from ZIP	2026-03-09 18:51:45.722056+00
97	ecb_press_releases_scrape	fetch_error	404 Client Error: Not Found for url: https://www.ecb.europa.eu/press/pr/date/2026/html/index.en.html	2026-03-09 18:51:45.722056+00
98	ecb_speeches_rss	fetch_error	404 Client Error: Not Found for url: https://www.ecb.europa.eu/rss/press.rss	2026-03-09 18:52:40.854213+00
99	ecb_sdw_series	fetch_error	series IRS.M.DE.L.L40.CI.0.EUR.2Y.NX: 404 Client Error:  for url: https://data-api.ecb.europa.eu/service/data/IRS/M.DE.L.L40.CI.0.EUR.2Y.NX?startPeriod=2025-03-09&endPeriod=2026-03-09&format=jsondata&detail=dataonly	2026-03-09 18:52:40.854213+00
100	ecb_sdw_series	fetch_error	series IRS.M.IT.L.L40.CI.0.EUR.10Y.NX: 404 Client Error:  for url: https://data-api.ecb.europa.eu/service/data/IRS/M.IT.L.L40.CI.0.EUR.10Y.NX?startPeriod=2025-03-09&endPeriod=2026-03-09&format=jsondata&detail=dataonly	2026-03-09 18:52:40.854213+00
101	cftc_cot_weekly	empty_result	Parsed 0 CoT rows from ZIP	2026-03-09 18:52:40.854213+00
102	ecb_press_releases_scrape	fetch_error	404 Client Error: Not Found for url: https://www.ecb.europa.eu/press/pr/date/2026/html/index.en.html	2026-03-09 18:52:40.854213+00
103	ecb_speeches_rss	fetch_error	404 Client Error: Not Found for url: https://www.ecb.europa.eu/rss/press.rss	2026-03-11 11:46:58.068274+00
104	ecb_sdw_series	fetch_error	series IRS.M.DE.L.L40.CI.0.EUR.2Y.NX: 404 Client Error:  for url: https://data-api.ecb.europa.eu/service/data/IRS/M.DE.L.L40.CI.0.EUR.2Y.NX?startPeriod=2025-03-11&endPeriod=2026-03-11&format=jsondata&detail=dataonly	2026-03-11 11:46:58.068274+00
105	ecb_sdw_series	fetch_error	series IRS.M.IT.L.L40.CI.0.EUR.10Y.NX: 404 Client Error:  for url: https://data-api.ecb.europa.eu/service/data/IRS/M.IT.L.L40.CI.0.EUR.10Y.NX?startPeriod=2025-03-11&endPeriod=2026-03-11&format=jsondata&detail=dataonly	2026-03-11 11:46:58.068274+00
106	cftc_cot_weekly	empty_result	Parsed 0 CoT rows from ZIP	2026-03-11 11:46:58.068274+00
107	ecb_press_releases_scrape	fetch_error	404 Client Error: Not Found for url: https://www.ecb.europa.eu/press/pr/date/2026/html/index.en.html	2026-03-11 11:46:58.068274+00
108	ecb_speeches_rss	fetch_error	404 Client Error: Not Found for url: https://www.ecb.europa.eu/rss/press.rss	2026-03-12 11:45:02.817837+00
109	ecb_sdw_series	fetch_error	series IRS.M.DE.L.L40.CI.0.EUR.2Y.NX: 404 Client Error:  for url: https://data-api.ecb.europa.eu/service/data/IRS/M.DE.L.L40.CI.0.EUR.2Y.NX?startPeriod=2025-03-12&endPeriod=2026-03-12&format=jsondata&detail=dataonly	2026-03-12 11:45:02.817837+00
110	ecb_sdw_series	fetch_error	series IRS.M.IT.L.L40.CI.0.EUR.10Y.NX: 404 Client Error:  for url: https://data-api.ecb.europa.eu/service/data/IRS/M.IT.L.L40.CI.0.EUR.10Y.NX?startPeriod=2025-03-12&endPeriod=2026-03-12&format=jsondata&detail=dataonly	2026-03-12 11:45:02.817837+00
111	cftc_cot_weekly	empty_result	Parsed 0 CoT rows from ZIP	2026-03-12 11:45:02.817837+00
112	ecb_press_releases_scrape	fetch_error	404 Client Error: Not Found for url: https://www.ecb.europa.eu/press/pr/date/2026/html/index.en.html	2026-03-12 11:45:02.817837+00
113	ecb_speeches_rss	fetch_error	404 Client Error: Not Found for url: https://www.ecb.europa.eu/rss/press.rss	2026-03-12 11:45:27.941442+00
114	ecb_sdw_series	fetch_error	series IRS.M.DE.L.L40.CI.0.EUR.2Y.NX: 404 Client Error:  for url: https://data-api.ecb.europa.eu/service/data/IRS/M.DE.L.L40.CI.0.EUR.2Y.NX?startPeriod=2025-03-12&endPeriod=2026-03-12&format=jsondata&detail=dataonly	2026-03-12 11:45:27.941442+00
115	ecb_sdw_series	fetch_error	series IRS.M.IT.L.L40.CI.0.EUR.10Y.NX: 404 Client Error:  for url: https://data-api.ecb.europa.eu/service/data/IRS/M.IT.L.L40.CI.0.EUR.10Y.NX?startPeriod=2025-03-12&endPeriod=2026-03-12&format=jsondata&detail=dataonly	2026-03-12 11:45:27.941442+00
116	cftc_cot_weekly	empty_result	Parsed 0 CoT rows from ZIP	2026-03-12 11:45:27.941442+00
117	ecb_press_releases_scrape	fetch_error	404 Client Error: Not Found for url: https://www.ecb.europa.eu/press/pr/date/2026/html/index.en.html	2026-03-12 11:45:27.941442+00
118	ecb_speeches_rss	fetch_error	404 Client Error: Not Found for url: https://www.ecb.europa.eu/rss/press.rss	2026-03-12 11:55:15.240044+00
119	ecb_sdw_series	fetch_error	series IRS.M.DE.L.L40.CI.0.EUR.2Y.NX: 404 Client Error:  for url: https://data-api.ecb.europa.eu/service/data/IRS/M.DE.L.L40.CI.0.EUR.2Y.NX?startPeriod=2025-03-12&endPeriod=2026-03-12&format=jsondata&detail=dataonly	2026-03-12 11:55:15.240044+00
120	ecb_sdw_series	fetch_error	series IRS.M.IT.L.L40.CI.0.EUR.10Y.NX: 404 Client Error:  for url: https://data-api.ecb.europa.eu/service/data/IRS/M.IT.L.L40.CI.0.EUR.10Y.NX?startPeriod=2025-03-12&endPeriod=2026-03-12&format=jsondata&detail=dataonly	2026-03-12 11:55:15.240044+00
121	cftc_cot_weekly	empty_result	Parsed 0 CoT rows from ZIP	2026-03-12 11:55:15.240044+00
122	ecb_press_releases_scrape	fetch_error	404 Client Error: Not Found for url: https://www.ecb.europa.eu/press/pr/date/2026/html/index.en.html	2026-03-12 11:55:15.240044+00
\.


--
-- Data for Name: positioning_signals; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.positioning_signals (id, date, series_id, net_spec, percentile_52w, crowding_flag, direction, computed_at) FROM stdin;
\.


--
-- Data for Name: regime_snapshots; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.regime_snapshots (id, date, growth_pulse, credit_stress, real_yield, dollar_strength, rates_vol, equity_vol, curve_shape, fingerprint, computed_at, growth_pulse_pct_90d, growth_pulse_pct_756d, credit_stress_pct_90d, credit_stress_pct_756d, real_yield_pct_90d, real_yield_pct_756d, dollar_strength_pct_90d, dollar_strength_pct_756d, rates_vol_pct_90d, rates_vol_pct_756d, equity_vol_pct_90d, equity_vol_pct_756d, curve_shape_pct_90d, curve_shape_pct_756d) FROM stdin;
10	2025-12-10	INSUFFICIENT_DATA	INSUFFICIENT_DATA	INSUFFICIENT_DATA	INSUFFICIENT_DATA	INSUFFICIENT_DATA	INSUFFICIENT_DATA	INSUFFICIENT_DATA	INSUFFICIENT_DATA-INSUFFICIENT_DATA-INSUFFICIENT_DATA-INSUFFICIENT_DATA-INSUFFICIENT_DATA-INSUFFICIENT_DATA-INSUFFICIENT_DATA	2026-03-10 15:51:10.266614+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
11	2025-12-11	INSUFFICIENT_DATA	INSUFFICIENT_DATA	INSUFFICIENT_DATA	INSUFFICIENT_DATA	INSUFFICIENT_DATA	INSUFFICIENT_DATA	INSUFFICIENT_DATA	INSUFFICIENT_DATA-INSUFFICIENT_DATA-INSUFFICIENT_DATA-INSUFFICIENT_DATA-INSUFFICIENT_DATA-INSUFFICIENT_DATA-INSUFFICIENT_DATA	2026-03-10 15:51:10.270873+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
12	2025-12-12	INSUFFICIENT_DATA	INSUFFICIENT_DATA	INSUFFICIENT_DATA	INSUFFICIENT_DATA	INSUFFICIENT_DATA	INSUFFICIENT_DATA	INSUFFICIENT_DATA	INSUFFICIENT_DATA-INSUFFICIENT_DATA-INSUFFICIENT_DATA-INSUFFICIENT_DATA-INSUFFICIENT_DATA-INSUFFICIENT_DATA-INSUFFICIENT_DATA	2026-03-10 15:51:10.272454+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
13	2025-12-13	INSUFFICIENT_DATA	INSUFFICIENT_DATA	INSUFFICIENT_DATA	INSUFFICIENT_DATA	INSUFFICIENT_DATA	INSUFFICIENT_DATA	INSUFFICIENT_DATA	INSUFFICIENT_DATA-INSUFFICIENT_DATA-INSUFFICIENT_DATA-INSUFFICIENT_DATA-INSUFFICIENT_DATA-INSUFFICIENT_DATA-INSUFFICIENT_DATA	2026-03-10 15:51:10.273787+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
14	2025-12-14	INSUFFICIENT_DATA	INSUFFICIENT_DATA	INSUFFICIENT_DATA	INSUFFICIENT_DATA	INSUFFICIENT_DATA	INSUFFICIENT_DATA	INSUFFICIENT_DATA	INSUFFICIENT_DATA-INSUFFICIENT_DATA-INSUFFICIENT_DATA-INSUFFICIENT_DATA-INSUFFICIENT_DATA-INSUFFICIENT_DATA-INSUFFICIENT_DATA	2026-03-10 15:51:10.275224+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
15	2025-12-15	SUPPRESSED	SUPPRESSED	INSUFFICIENT_DATA	SUPPRESSED	ELEVATED	ELEVATED	INSUFFICIENT_DATA	SUPPRESSED-SUPPRESSED-INSUFFICIENT_DATA-SUPPRESSED-ELEVATED-ELEVATED-INSUFFICIENT_DATA	2026-03-10 15:51:10.276469+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9	2025-12-09	INSUFFICIENT_DATA	INSUFFICIENT_DATA	INSUFFICIENT_DATA	INSUFFICIENT_DATA	INSUFFICIENT_DATA	INSUFFICIENT_DATA	INSUFFICIENT_DATA	INSUFFICIENT_DATA-INSUFFICIENT_DATA-INSUFFICIENT_DATA-INSUFFICIENT_DATA-INSUFFICIENT_DATA-INSUFFICIENT_DATA-INSUFFICIENT_DATA	2026-03-09 19:24:17.444646+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
16	2025-12-16	SUPPRESSED	NORMAL	INSUFFICIENT_DATA	SUPPRESSED	SUPPRESSED	NORMAL	INSUFFICIENT_DATA	SUPPRESSED-NORMAL-INSUFFICIENT_DATA-SUPPRESSED-SUPPRESSED-NORMAL-INSUFFICIENT_DATA	2026-03-10 15:51:10.277758+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
17	2025-12-17	NORMAL	SUPPRESSED	INSUFFICIENT_DATA	NORMAL	SUPPRESSED	ELEVATED	INSUFFICIENT_DATA	NORMAL-SUPPRESSED-INSUFFICIENT_DATA-NORMAL-SUPPRESSED-ELEVATED-INSUFFICIENT_DATA	2026-03-10 15:51:10.279013+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
18	2025-12-18	NORMAL	ELEVATED	INSUFFICIENT_DATA	NORMAL	SUPPRESSED	NORMAL	INSUFFICIENT_DATA	NORMAL-ELEVATED-INSUFFICIENT_DATA-NORMAL-SUPPRESSED-NORMAL-INSUFFICIENT_DATA	2026-03-10 15:51:10.281282+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
19	2025-12-19	ELEVATED	ELEVATED	INSUFFICIENT_DATA	ELEVATED	SUPPRESSED	SUPPRESSED	INSUFFICIENT_DATA	ELEVATED-ELEVATED-INSUFFICIENT_DATA-ELEVATED-SUPPRESSED-SUPPRESSED-INSUFFICIENT_DATA	2026-03-10 15:51:10.283072+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
20	2025-12-20	INSUFFICIENT_DATA	ELEVATED	INSUFFICIENT_DATA	ELEVATED	SUPPRESSED	SUPPRESSED	INSUFFICIENT_DATA	INSUFFICIENT_DATA-ELEVATED-INSUFFICIENT_DATA-ELEVATED-SUPPRESSED-SUPPRESSED-INSUFFICIENT_DATA	2026-03-10 15:51:10.285206+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
21	2025-12-21	INSUFFICIENT_DATA	ELEVATED	INSUFFICIENT_DATA	ELEVATED	SUPPRESSED	SUPPRESSED	INSUFFICIENT_DATA	INSUFFICIENT_DATA-ELEVATED-INSUFFICIENT_DATA-ELEVATED-SUPPRESSED-SUPPRESSED-INSUFFICIENT_DATA	2026-03-10 15:51:10.287449+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
22	2025-12-22	SUPPRESSED	ELEVATED	INSUFFICIENT_DATA	SUPPRESSED	SUPPRESSED	SUPPRESSED	INSUFFICIENT_DATA	SUPPRESSED-ELEVATED-INSUFFICIENT_DATA-SUPPRESSED-SUPPRESSED-SUPPRESSED-INSUFFICIENT_DATA	2026-03-10 15:51:10.289122+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
23	2025-12-23	SUPPRESSED	ELEVATED	INSUFFICIENT_DATA	SUPPRESSED	SUPPRESSED	SUPPRESSED	INSUFFICIENT_DATA	SUPPRESSED-ELEVATED-INSUFFICIENT_DATA-SUPPRESSED-SUPPRESSED-SUPPRESSED-INSUFFICIENT_DATA	2026-03-10 15:51:10.292595+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
24	2025-12-24	SUPPRESSED	ELEVATED	INSUFFICIENT_DATA	SUPPRESSED	SUPPRESSED	SUPPRESSED	INSUFFICIENT_DATA	SUPPRESSED-ELEVATED-INSUFFICIENT_DATA-SUPPRESSED-SUPPRESSED-SUPPRESSED-INSUFFICIENT_DATA	2026-03-10 15:51:10.294711+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
25	2025-12-25	INSUFFICIENT_DATA	ELEVATED	INSUFFICIENT_DATA	SUPPRESSED	SUPPRESSED	SUPPRESSED	INSUFFICIENT_DATA	INSUFFICIENT_DATA-ELEVATED-INSUFFICIENT_DATA-SUPPRESSED-SUPPRESSED-SUPPRESSED-INSUFFICIENT_DATA	2026-03-10 15:51:10.296946+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
26	2025-12-26	ELEVATED	ELEVATED	INSUFFICIENT_DATA	SUPPRESSED	SUPPRESSED	SUPPRESSED	INSUFFICIENT_DATA	ELEVATED-ELEVATED-INSUFFICIENT_DATA-SUPPRESSED-SUPPRESSED-SUPPRESSED-INSUFFICIENT_DATA	2026-03-10 15:51:10.298727+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
27	2025-12-27	INSUFFICIENT_DATA	ELEVATED	INSUFFICIENT_DATA	SUPPRESSED	SUPPRESSED	SUPPRESSED	INSUFFICIENT_DATA	INSUFFICIENT_DATA-ELEVATED-INSUFFICIENT_DATA-SUPPRESSED-SUPPRESSED-SUPPRESSED-INSUFFICIENT_DATA	2026-03-10 15:51:10.299831+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
28	2025-12-28	INSUFFICIENT_DATA	ELEVATED	INSUFFICIENT_DATA	SUPPRESSED	SUPPRESSED	SUPPRESSED	INSUFFICIENT_DATA	INSUFFICIENT_DATA-ELEVATED-INSUFFICIENT_DATA-SUPPRESSED-SUPPRESSED-SUPPRESSED-INSUFFICIENT_DATA	2026-03-10 15:51:10.301791+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
29	2025-12-29	ELEVATED	ELEVATED	INSUFFICIENT_DATA	SUPPRESSED	SUPPRESSED	NORMAL	INSUFFICIENT_DATA	ELEVATED-ELEVATED-INSUFFICIENT_DATA-SUPPRESSED-SUPPRESSED-NORMAL-INSUFFICIENT_DATA	2026-03-10 15:51:10.303766+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
30	2025-12-30	ELEVATED	ELEVATED	INSUFFICIENT_DATA	NORMAL	NORMAL	NORMAL	INSUFFICIENT_DATA	ELEVATED-ELEVATED-INSUFFICIENT_DATA-NORMAL-NORMAL-NORMAL-INSUFFICIENT_DATA	2026-03-10 15:51:10.305633+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
31	2025-12-31	ELEVATED	NORMAL	INSUFFICIENT_DATA	NORMAL	NORMAL	NORMAL	INSUFFICIENT_DATA	ELEVATED-NORMAL-INSUFFICIENT_DATA-NORMAL-NORMAL-NORMAL-INSUFFICIENT_DATA	2026-03-10 15:51:10.306951+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
32	2026-01-01	INSUFFICIENT_DATA	NORMAL	INSUFFICIENT_DATA	NORMAL	NORMAL	NORMAL	INSUFFICIENT_DATA	INSUFFICIENT_DATA-NORMAL-INSUFFICIENT_DATA-NORMAL-NORMAL-NORMAL-INSUFFICIENT_DATA	2026-03-10 15:51:10.308059+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
33	2026-01-02	ELEVATED	ELEVATED	INSUFFICIENT_DATA	ELEVATED	NORMAL	NORMAL	INSUFFICIENT_DATA	ELEVATED-ELEVATED-INSUFFICIENT_DATA-ELEVATED-NORMAL-NORMAL-INSUFFICIENT_DATA	2026-03-10 15:51:10.309194+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
34	2026-01-03	INSUFFICIENT_DATA	ELEVATED	INSUFFICIENT_DATA	ELEVATED	NORMAL	NORMAL	INSUFFICIENT_DATA	INSUFFICIENT_DATA-ELEVATED-INSUFFICIENT_DATA-ELEVATED-NORMAL-NORMAL-INSUFFICIENT_DATA	2026-03-10 15:51:10.311392+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
35	2026-01-04	INSUFFICIENT_DATA	ELEVATED	INSUFFICIENT_DATA	ELEVATED	NORMAL	NORMAL	INSUFFICIENT_DATA	INSUFFICIENT_DATA-ELEVATED-INSUFFICIENT_DATA-ELEVATED-NORMAL-NORMAL-INSUFFICIENT_DATA	2026-03-10 15:51:10.313819+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
36	2026-01-05	ELEVATED	ELEVATED	INSUFFICIENT_DATA	NORMAL	NORMAL	NORMAL	INSUFFICIENT_DATA	ELEVATED-ELEVATED-INSUFFICIENT_DATA-NORMAL-NORMAL-NORMAL-INSUFFICIENT_DATA	2026-03-10 15:51:10.316661+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
37	2026-01-06	ELEVATED	ELEVATED	INSUFFICIENT_DATA	ELEVATED	NORMAL	NORMAL	INSUFFICIENT_DATA	ELEVATED-ELEVATED-INSUFFICIENT_DATA-ELEVATED-NORMAL-NORMAL-INSUFFICIENT_DATA	2026-03-10 15:51:10.318755+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
38	2026-01-07	ELEVATED	ELEVATED	INSUFFICIENT_DATA	ELEVATED	NORMAL	NORMAL	INSUFFICIENT_DATA	ELEVATED-ELEVATED-INSUFFICIENT_DATA-ELEVATED-NORMAL-NORMAL-INSUFFICIENT_DATA	2026-03-10 15:51:10.320735+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
39	2026-01-08	NORMAL	ELEVATED	INSUFFICIENT_DATA	ELEVATED	NORMAL	NORMAL	INSUFFICIENT_DATA	NORMAL-ELEVATED-INSUFFICIENT_DATA-ELEVATED-NORMAL-NORMAL-INSUFFICIENT_DATA	2026-03-10 15:51:10.322316+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
40	2026-01-09	ELEVATED	ELEVATED	INSUFFICIENT_DATA	ELEVATED	NORMAL	NORMAL	INSUFFICIENT_DATA	ELEVATED-ELEVATED-INSUFFICIENT_DATA-ELEVATED-NORMAL-NORMAL-INSUFFICIENT_DATA	2026-03-10 15:51:10.324156+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1	2026-03-09	SUPPRESSED	SUPPRESSED	INSUFFICIENT_DATA	ELEVATED	ELEVATED	ELEVATED	INSUFFICIENT_DATA	SUPPRESSED-SUPPRESSED-INSUFFICIENT_DATA-ELEVATED-ELEVATED-ELEVATED-INSUFFICIENT_DATA	2026-03-10 15:51:10.534089+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
43	2026-01-12	NORMAL	ELEVATED	INSUFFICIENT_DATA	ELEVATED	NORMAL	NORMAL	INSUFFICIENT_DATA	NORMAL-ELEVATED-INSUFFICIENT_DATA-ELEVATED-NORMAL-NORMAL-INSUFFICIENT_DATA	2026-03-10 15:51:10.33033+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
44	2026-01-13	NORMAL	ELEVATED	INSUFFICIENT_DATA	ELEVATED	SUPPRESSED	ELEVATED	INSUFFICIENT_DATA	NORMAL-ELEVATED-INSUFFICIENT_DATA-ELEVATED-SUPPRESSED-ELEVATED-INSUFFICIENT_DATA	2026-03-10 15:51:10.33221+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
45	2026-01-14	NORMAL	ELEVATED	INSUFFICIENT_DATA	ELEVATED	SUPPRESSED	ELEVATED	INSUFFICIENT_DATA	NORMAL-ELEVATED-INSUFFICIENT_DATA-ELEVATED-SUPPRESSED-ELEVATED-INSUFFICIENT_DATA	2026-03-10 15:51:10.334439+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
46	2026-01-15	NORMAL	ELEVATED	INSUFFICIENT_DATA	ELEVATED	SUPPRESSED	NORMAL	INSUFFICIENT_DATA	NORMAL-ELEVATED-INSUFFICIENT_DATA-ELEVATED-SUPPRESSED-NORMAL-INSUFFICIENT_DATA	2026-03-10 15:51:10.337811+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
47	2026-01-16	NORMAL	ELEVATED	INSUFFICIENT_DATA	ELEVATED	SUPPRESSED	NORMAL	INSUFFICIENT_DATA	NORMAL-ELEVATED-INSUFFICIENT_DATA-ELEVATED-SUPPRESSED-NORMAL-INSUFFICIENT_DATA	2026-03-10 15:51:10.340706+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
48	2026-01-17	INSUFFICIENT_DATA	ELEVATED	INSUFFICIENT_DATA	ELEVATED	SUPPRESSED	NORMAL	INSUFFICIENT_DATA	INSUFFICIENT_DATA-ELEVATED-INSUFFICIENT_DATA-ELEVATED-SUPPRESSED-NORMAL-INSUFFICIENT_DATA	2026-03-10 15:51:10.343845+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
50	2026-01-19	INSUFFICIENT_DATA	ELEVATED	INSUFFICIENT_DATA	ELEVATED	SUPPRESSED	NORMAL	INSUFFICIENT_DATA	INSUFFICIENT_DATA-ELEVATED-INSUFFICIENT_DATA-ELEVATED-SUPPRESSED-NORMAL-INSUFFICIENT_DATA	2026-03-10 15:51:10.349304+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
51	2026-01-20	SUPPRESSED	NORMAL	INSUFFICIENT_DATA	NORMAL	NORMAL	ELEVATED	INSUFFICIENT_DATA	SUPPRESSED-NORMAL-INSUFFICIENT_DATA-NORMAL-NORMAL-ELEVATED-INSUFFICIENT_DATA	2026-03-10 15:51:10.351879+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
52	2026-01-21	SUPPRESSED	ELEVATED	INSUFFICIENT_DATA	NORMAL	SUPPRESSED	ELEVATED	INSUFFICIENT_DATA	SUPPRESSED-ELEVATED-INSUFFICIENT_DATA-NORMAL-SUPPRESSED-ELEVATED-INSUFFICIENT_DATA	2026-03-10 15:51:10.354358+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
53	2026-01-22	SUPPRESSED	ELEVATED	INSUFFICIENT_DATA	NORMAL	SUPPRESSED	NORMAL	INSUFFICIENT_DATA	SUPPRESSED-ELEVATED-INSUFFICIENT_DATA-NORMAL-SUPPRESSED-NORMAL-INSUFFICIENT_DATA	2026-03-10 15:51:10.356825+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
55	2026-01-24	INSUFFICIENT_DATA	ELEVATED	INSUFFICIENT_DATA	SUPPRESSED	SUPPRESSED	NORMAL	INSUFFICIENT_DATA	INSUFFICIENT_DATA-ELEVATED-INSUFFICIENT_DATA-SUPPRESSED-SUPPRESSED-NORMAL-INSUFFICIENT_DATA	2026-03-10 15:51:10.362031+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
56	2026-01-25	INSUFFICIENT_DATA	ELEVATED	INSUFFICIENT_DATA	SUPPRESSED	SUPPRESSED	NORMAL	INSUFFICIENT_DATA	INSUFFICIENT_DATA-ELEVATED-INSUFFICIENT_DATA-SUPPRESSED-SUPPRESSED-NORMAL-INSUFFICIENT_DATA	2026-03-10 15:51:10.364854+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
57	2026-01-26	SUPPRESSED	ELEVATED	INSUFFICIENT_DATA	SUPPRESSED	SUPPRESSED	NORMAL	INSUFFICIENT_DATA	SUPPRESSED-ELEVATED-INSUFFICIENT_DATA-SUPPRESSED-SUPPRESSED-NORMAL-INSUFFICIENT_DATA	2026-03-10 15:51:10.367556+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
58	2026-01-27	SUPPRESSED	ELEVATED	INSUFFICIENT_DATA	SUPPRESSED	SUPPRESSED	ELEVATED	INSUFFICIENT_DATA	SUPPRESSED-ELEVATED-INSUFFICIENT_DATA-SUPPRESSED-SUPPRESSED-ELEVATED-INSUFFICIENT_DATA	2026-03-10 15:51:10.370296+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
59	2026-01-28	SUPPRESSED	NORMAL	INSUFFICIENT_DATA	SUPPRESSED	SUPPRESSED	ELEVATED	INSUFFICIENT_DATA	SUPPRESSED-NORMAL-INSUFFICIENT_DATA-SUPPRESSED-SUPPRESSED-ELEVATED-INSUFFICIENT_DATA	2026-03-10 15:51:10.372904+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
61	2026-01-30	NORMAL	NORMAL	INSUFFICIENT_DATA	SUPPRESSED	SUPPRESSED	ELEVATED	INSUFFICIENT_DATA	NORMAL-NORMAL-INSUFFICIENT_DATA-SUPPRESSED-SUPPRESSED-ELEVATED-INSUFFICIENT_DATA	2026-03-10 15:51:10.379487+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
62	2026-01-31	INSUFFICIENT_DATA	NORMAL	INSUFFICIENT_DATA	SUPPRESSED	SUPPRESSED	ELEVATED	INSUFFICIENT_DATA	INSUFFICIENT_DATA-NORMAL-INSUFFICIENT_DATA-SUPPRESSED-SUPPRESSED-ELEVATED-INSUFFICIENT_DATA	2026-03-10 15:51:10.382517+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
63	2026-02-01	INSUFFICIENT_DATA	NORMAL	INSUFFICIENT_DATA	SUPPRESSED	SUPPRESSED	ELEVATED	INSUFFICIENT_DATA	INSUFFICIENT_DATA-NORMAL-INSUFFICIENT_DATA-SUPPRESSED-SUPPRESSED-ELEVATED-INSUFFICIENT_DATA	2026-03-10 15:51:10.385698+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
64	2026-02-02	NORMAL	SUPPRESSED	INSUFFICIENT_DATA	SUPPRESSED	NORMAL	NORMAL	INSUFFICIENT_DATA	NORMAL-SUPPRESSED-INSUFFICIENT_DATA-SUPPRESSED-NORMAL-NORMAL-INSUFFICIENT_DATA	2026-03-10 15:51:10.390576+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
65	2026-02-03	NORMAL	SUPPRESSED	INSUFFICIENT_DATA	SUPPRESSED	SUPPRESSED	ELEVATED	INSUFFICIENT_DATA	NORMAL-SUPPRESSED-INSUFFICIENT_DATA-SUPPRESSED-SUPPRESSED-ELEVATED-INSUFFICIENT_DATA	2026-03-10 15:51:10.394252+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
67	2026-02-05	SUPPRESSED	SUPPRESSED	INSUFFICIENT_DATA	SUPPRESSED	NORMAL	ELEVATED	INSUFFICIENT_DATA	SUPPRESSED-SUPPRESSED-INSUFFICIENT_DATA-SUPPRESSED-NORMAL-ELEVATED-INSUFFICIENT_DATA	2026-03-10 15:51:10.400537+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
68	2026-02-06	SUPPRESSED	SUPPRESSED	INSUFFICIENT_DATA	SUPPRESSED	NORMAL	ELEVATED	INSUFFICIENT_DATA	SUPPRESSED-SUPPRESSED-INSUFFICIENT_DATA-SUPPRESSED-NORMAL-ELEVATED-INSUFFICIENT_DATA	2026-03-10 15:51:10.403486+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
69	2026-02-07	INSUFFICIENT_DATA	SUPPRESSED	INSUFFICIENT_DATA	SUPPRESSED	NORMAL	ELEVATED	INSUFFICIENT_DATA	INSUFFICIENT_DATA-SUPPRESSED-INSUFFICIENT_DATA-SUPPRESSED-NORMAL-ELEVATED-INSUFFICIENT_DATA	2026-03-10 15:51:10.406964+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
70	2026-02-08	INSUFFICIENT_DATA	SUPPRESSED	INSUFFICIENT_DATA	SUPPRESSED	NORMAL	ELEVATED	INSUFFICIENT_DATA	INSUFFICIENT_DATA-SUPPRESSED-INSUFFICIENT_DATA-SUPPRESSED-NORMAL-ELEVATED-INSUFFICIENT_DATA	2026-03-10 15:51:10.411902+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
71	2026-02-09	SUPPRESSED	NORMAL	INSUFFICIENT_DATA	SUPPRESSED	NORMAL	ELEVATED	INSUFFICIENT_DATA	SUPPRESSED-NORMAL-INSUFFICIENT_DATA-SUPPRESSED-NORMAL-ELEVATED-INSUFFICIENT_DATA	2026-03-10 15:51:10.41523+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
73	2026-02-11	SUPPRESSED	SUPPRESSED	INSUFFICIENT_DATA	SUPPRESSED	NORMAL	ELEVATED	INSUFFICIENT_DATA	SUPPRESSED-SUPPRESSED-INSUFFICIENT_DATA-SUPPRESSED-NORMAL-ELEVATED-INSUFFICIENT_DATA	2026-03-10 15:51:10.421987+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
74	2026-02-12	SUPPRESSED	SUPPRESSED	INSUFFICIENT_DATA	SUPPRESSED	ELEVATED	ELEVATED	INSUFFICIENT_DATA	SUPPRESSED-SUPPRESSED-INSUFFICIENT_DATA-SUPPRESSED-ELEVATED-ELEVATED-INSUFFICIENT_DATA	2026-03-10 15:51:10.425946+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
75	2026-02-13	SUPPRESSED	NORMAL	INSUFFICIENT_DATA	SUPPRESSED	ELEVATED	ELEVATED	INSUFFICIENT_DATA	SUPPRESSED-NORMAL-INSUFFICIENT_DATA-SUPPRESSED-ELEVATED-ELEVATED-INSUFFICIENT_DATA	2026-03-10 15:51:10.429315+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
76	2026-02-14	INSUFFICIENT_DATA	NORMAL	INSUFFICIENT_DATA	SUPPRESSED	ELEVATED	ELEVATED	INSUFFICIENT_DATA	INSUFFICIENT_DATA-NORMAL-INSUFFICIENT_DATA-SUPPRESSED-ELEVATED-ELEVATED-INSUFFICIENT_DATA	2026-03-10 15:51:10.432458+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
77	2026-02-15	INSUFFICIENT_DATA	NORMAL	INSUFFICIENT_DATA	SUPPRESSED	ELEVATED	ELEVATED	INSUFFICIENT_DATA	INSUFFICIENT_DATA-NORMAL-INSUFFICIENT_DATA-SUPPRESSED-ELEVATED-ELEVATED-INSUFFICIENT_DATA	2026-03-10 15:51:10.436703+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
79	2026-02-17	SUPPRESSED	SUPPRESSED	INSUFFICIENT_DATA	SUPPRESSED	ELEVATED	ELEVATED	INSUFFICIENT_DATA	SUPPRESSED-SUPPRESSED-INSUFFICIENT_DATA-SUPPRESSED-ELEVATED-ELEVATED-INSUFFICIENT_DATA	2026-03-10 15:51:10.443988+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
80	2026-02-18	SUPPRESSED	NORMAL	INSUFFICIENT_DATA	NORMAL	NORMAL	ELEVATED	INSUFFICIENT_DATA	SUPPRESSED-NORMAL-INSUFFICIENT_DATA-NORMAL-NORMAL-ELEVATED-INSUFFICIENT_DATA	2026-03-10 15:51:10.447601+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
81	2026-02-19	SUPPRESSED	NORMAL	INSUFFICIENT_DATA	NORMAL	ELEVATED	ELEVATED	INSUFFICIENT_DATA	SUPPRESSED-NORMAL-INSUFFICIENT_DATA-NORMAL-ELEVATED-ELEVATED-INSUFFICIENT_DATA	2026-03-10 15:51:10.451239+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
82	2026-02-20	SUPPRESSED	NORMAL	INSUFFICIENT_DATA	NORMAL	NORMAL	ELEVATED	INSUFFICIENT_DATA	SUPPRESSED-NORMAL-INSUFFICIENT_DATA-NORMAL-NORMAL-ELEVATED-INSUFFICIENT_DATA	2026-03-10 15:51:10.455152+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
83	2026-02-21	INSUFFICIENT_DATA	NORMAL	INSUFFICIENT_DATA	NORMAL	NORMAL	ELEVATED	INSUFFICIENT_DATA	INSUFFICIENT_DATA-NORMAL-INSUFFICIENT_DATA-NORMAL-NORMAL-ELEVATED-INSUFFICIENT_DATA	2026-03-10 15:51:10.459409+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
84	2026-02-22	INSUFFICIENT_DATA	NORMAL	INSUFFICIENT_DATA	NORMAL	NORMAL	ELEVATED	INSUFFICIENT_DATA	INSUFFICIENT_DATA-NORMAL-INSUFFICIENT_DATA-NORMAL-NORMAL-ELEVATED-INSUFFICIENT_DATA	2026-03-10 15:51:10.464085+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
41	2026-01-10	INSUFFICIENT_DATA	ELEVATED	INSUFFICIENT_DATA	ELEVATED	NORMAL	NORMAL	INSUFFICIENT_DATA	INSUFFICIENT_DATA-ELEVATED-INSUFFICIENT_DATA-ELEVATED-NORMAL-NORMAL-INSUFFICIENT_DATA	2026-03-10 15:51:10.325944+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
42	2026-01-11	INSUFFICIENT_DATA	ELEVATED	INSUFFICIENT_DATA	ELEVATED	NORMAL	NORMAL	INSUFFICIENT_DATA	INSUFFICIENT_DATA-ELEVATED-INSUFFICIENT_DATA-ELEVATED-NORMAL-NORMAL-INSUFFICIENT_DATA	2026-03-10 15:51:10.328177+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
49	2026-01-18	INSUFFICIENT_DATA	ELEVATED	INSUFFICIENT_DATA	ELEVATED	SUPPRESSED	NORMAL	INSUFFICIENT_DATA	INSUFFICIENT_DATA-ELEVATED-INSUFFICIENT_DATA-ELEVATED-SUPPRESSED-NORMAL-INSUFFICIENT_DATA	2026-03-10 15:51:10.346553+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
54	2026-01-23	SUPPRESSED	ELEVATED	INSUFFICIENT_DATA	SUPPRESSED	SUPPRESSED	NORMAL	INSUFFICIENT_DATA	SUPPRESSED-ELEVATED-INSUFFICIENT_DATA-SUPPRESSED-SUPPRESSED-NORMAL-INSUFFICIENT_DATA	2026-03-10 15:51:10.359407+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
60	2026-01-29	SUPPRESSED	NORMAL	INSUFFICIENT_DATA	SUPPRESSED	NORMAL	ELEVATED	INSUFFICIENT_DATA	SUPPRESSED-NORMAL-INSUFFICIENT_DATA-SUPPRESSED-NORMAL-ELEVATED-INSUFFICIENT_DATA	2026-03-10 15:51:10.37618+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
66	2026-02-04	SUPPRESSED	SUPPRESSED	INSUFFICIENT_DATA	SUPPRESSED	SUPPRESSED	ELEVATED	INSUFFICIENT_DATA	SUPPRESSED-SUPPRESSED-INSUFFICIENT_DATA-SUPPRESSED-SUPPRESSED-ELEVATED-INSUFFICIENT_DATA	2026-03-10 15:51:10.397436+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
72	2026-02-10	SUPPRESSED	NORMAL	INSUFFICIENT_DATA	SUPPRESSED	NORMAL	ELEVATED	INSUFFICIENT_DATA	SUPPRESSED-NORMAL-INSUFFICIENT_DATA-SUPPRESSED-NORMAL-ELEVATED-INSUFFICIENT_DATA	2026-03-10 15:51:10.418549+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
78	2026-02-16	INSUFFICIENT_DATA	NORMAL	INSUFFICIENT_DATA	SUPPRESSED	ELEVATED	ELEVATED	INSUFFICIENT_DATA	INSUFFICIENT_DATA-NORMAL-INSUFFICIENT_DATA-SUPPRESSED-ELEVATED-ELEVATED-INSUFFICIENT_DATA	2026-03-10 15:51:10.440658+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
85	2026-02-23	SUPPRESSED	NORMAL	INSUFFICIENT_DATA	NORMAL	ELEVATED	ELEVATED	INSUFFICIENT_DATA	SUPPRESSED-NORMAL-INSUFFICIENT_DATA-NORMAL-ELEVATED-ELEVATED-INSUFFICIENT_DATA	2026-03-10 15:51:10.468915+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
86	2026-02-24	SUPPRESSED	SUPPRESSED	INSUFFICIENT_DATA	NORMAL	NORMAL	ELEVATED	INSUFFICIENT_DATA	SUPPRESSED-SUPPRESSED-INSUFFICIENT_DATA-NORMAL-NORMAL-ELEVATED-INSUFFICIENT_DATA	2026-03-10 15:51:10.473409+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
87	2026-02-25	SUPPRESSED	NORMAL	INSUFFICIENT_DATA	NORMAL	NORMAL	ELEVATED	INSUFFICIENT_DATA	SUPPRESSED-NORMAL-INSUFFICIENT_DATA-NORMAL-NORMAL-ELEVATED-INSUFFICIENT_DATA	2026-03-10 15:51:10.477982+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
88	2026-02-26	SUPPRESSED	SUPPRESSED	INSUFFICIENT_DATA	NORMAL	NORMAL	ELEVATED	INSUFFICIENT_DATA	SUPPRESSED-SUPPRESSED-INSUFFICIENT_DATA-NORMAL-NORMAL-ELEVATED-INSUFFICIENT_DATA	2026-03-10 15:51:10.482732+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
89	2026-02-27	SUPPRESSED	SUPPRESSED	INSUFFICIENT_DATA	SUPPRESSED	ELEVATED	ELEVATED	INSUFFICIENT_DATA	SUPPRESSED-SUPPRESSED-INSUFFICIENT_DATA-SUPPRESSED-ELEVATED-ELEVATED-INSUFFICIENT_DATA	2026-03-10 15:51:10.487587+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
90	2026-02-28	INSUFFICIENT_DATA	SUPPRESSED	INSUFFICIENT_DATA	SUPPRESSED	ELEVATED	ELEVATED	INSUFFICIENT_DATA	INSUFFICIENT_DATA-SUPPRESSED-INSUFFICIENT_DATA-SUPPRESSED-ELEVATED-ELEVATED-INSUFFICIENT_DATA	2026-03-10 15:51:10.492733+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
91	2026-03-01	INSUFFICIENT_DATA	SUPPRESSED	INSUFFICIENT_DATA	SUPPRESSED	ELEVATED	ELEVATED	INSUFFICIENT_DATA	INSUFFICIENT_DATA-SUPPRESSED-INSUFFICIENT_DATA-SUPPRESSED-ELEVATED-ELEVATED-INSUFFICIENT_DATA	2026-03-10 15:51:10.497448+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
92	2026-03-02	SUPPRESSED	SUPPRESSED	INSUFFICIENT_DATA	NORMAL	ELEVATED	ELEVATED	INSUFFICIENT_DATA	SUPPRESSED-SUPPRESSED-INSUFFICIENT_DATA-NORMAL-ELEVATED-ELEVATED-INSUFFICIENT_DATA	2026-03-10 15:51:10.503062+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
93	2026-03-03	SUPPRESSED	SUPPRESSED	INSUFFICIENT_DATA	ELEVATED	ELEVATED	ELEVATED	INSUFFICIENT_DATA	SUPPRESSED-SUPPRESSED-INSUFFICIENT_DATA-ELEVATED-ELEVATED-ELEVATED-INSUFFICIENT_DATA	2026-03-10 15:51:10.507518+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
94	2026-03-04	SUPPRESSED	SUPPRESSED	INSUFFICIENT_DATA	ELEVATED	ELEVATED	ELEVATED	INSUFFICIENT_DATA	SUPPRESSED-SUPPRESSED-INSUFFICIENT_DATA-ELEVATED-ELEVATED-ELEVATED-INSUFFICIENT_DATA	2026-03-10 15:51:10.511456+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
95	2026-03-05	SUPPRESSED	SUPPRESSED	INSUFFICIENT_DATA	ELEVATED	ELEVATED	ELEVATED	INSUFFICIENT_DATA	SUPPRESSED-SUPPRESSED-INSUFFICIENT_DATA-ELEVATED-ELEVATED-ELEVATED-INSUFFICIENT_DATA	2026-03-10 15:51:10.51545+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
96	2026-03-06	SUPPRESSED	SUPPRESSED	INSUFFICIENT_DATA	ELEVATED	ELEVATED	ELEVATED	INSUFFICIENT_DATA	SUPPRESSED-SUPPRESSED-INSUFFICIENT_DATA-ELEVATED-ELEVATED-ELEVATED-INSUFFICIENT_DATA	2026-03-10 15:51:10.519877+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
97	2026-03-07	INSUFFICIENT_DATA	SUPPRESSED	INSUFFICIENT_DATA	ELEVATED	ELEVATED	ELEVATED	INSUFFICIENT_DATA	INSUFFICIENT_DATA-SUPPRESSED-INSUFFICIENT_DATA-ELEVATED-ELEVATED-ELEVATED-INSUFFICIENT_DATA	2026-03-10 15:51:10.524578+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
98	2026-03-08	INSUFFICIENT_DATA	SUPPRESSED	INSUFFICIENT_DATA	ELEVATED	ELEVATED	ELEVATED	INSUFFICIENT_DATA	INSUFFICIENT_DATA-SUPPRESSED-INSUFFICIENT_DATA-ELEVATED-ELEVATED-ELEVATED-INSUFFICIENT_DATA	2026-03-10 15:51:10.529243+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
190	2026-03-10	INSUFFICIENT_DATA	SUPPRESSED	INSUFFICIENT_DATA	ELEVATED	ELEVATED	ELEVATED	INSUFFICIENT_DATA	INSUFFICIENT_DATA-SUPPRESSED-INSUFFICIENT_DATA-ELEVATED-ELEVATED-ELEVATED-INSUFFICIENT_DATA	2026-03-10 15:51:10.53849+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
191	2026-03-11	INSUFFICIENT_DATA	SUPPRESSED	INSUFFICIENT_DATA	ELEVATED	ELEVATED	ELEVATED	INSUFFICIENT_DATA	INSUFFICIENT_DATA-SUPPRESSED-INSUFFICIENT_DATA-ELEVATED-ELEVATED-ELEVATED-INSUFFICIENT_DATA	2026-03-11 11:47:10.372337+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
192	2026-03-12	INSUFFICIENT_DATA	SUPPRESSED	INSUFFICIENT_DATA	ELEVATED	ELEVATED	ELEVATED	INSUFFICIENT_DATA	INSUFFICIENT_DATA-SUPPRESSED-INSUFFICIENT_DATA-ELEVATED-ELEVATED-ELEVATED-INSUFFICIENT_DATA	2026-03-12 11:55:26.952114+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
195	2026-04-05	INSUFFICIENT_DATA	SUPPRESSED	INSUFFICIENT_DATA	ELEVATED	ELEVATED	ELEVATED	INSUFFICIENT_DATA	INSUFFICIENT_DATA-SUPPRESSED-INSUFFICIENT_DATA-ELEVATED-ELEVATED-ELEVATED-INSUFFICIENT_DATA	2026-04-05 18:32:25.463714+01	50	50	2	2	50	50	94	94	95	95	94	94	50	50
\.


--
-- Data for Name: research_theses; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.research_theses (id, title, content_html, tags, status, created_at, updated_at, last_auto_saved, metadata, canvas_layout) FROM stdin;
f216a10e-182f-481a-856c-7d1823e1f6c6	SP500	<br><p><br></p><br><br><div class="thesis-chart-embed" contenteditable="false" data-embed-id="embed_1773258487500_g7l2e" data-type="overlaid" data-x="CM.BRENT" data-y="EQ.SPX" data-period="180" data-shock-pct="10" data-instruments="CM.BRENT,EQ.SPX"><div class="chart-embed-header"><span class="chart-embed-label">Brent Crude Oil vs S&amp;P 500 Index — Overlaid</span><div class="chart-embed-actions"><button type="button" class="chart-embed-btn chart-embed-settings">Settings</button><button type="button" class="chart-embed-btn chart-embed-refresh">Refresh</button><button type="button" class="chart-embed-btn chart-embed-remove">Remove</button></div></div><div class="chart-embed-canvas"></div><div class="chart-embed-meta">Last updated 17:08 · Brent Crude Oil vs S&amp;P 500 Index — Overlaid</div></div><p><br></p>	{}	draft	2026-03-17 18:45:34.349844+00	2026-03-17 18:45:34.365758+00	\N	{}	\N
b0098003-6b01-449a-8d44-6e9d4aa615b0	Oil	@<br><p><br></p><p><br></p><p><br></p>	{}	draft	2026-03-17 18:45:34.398712+00	2026-03-22 14:56:16.222827+00	2026-03-22 14:56:16.222827+00	{"board_cards": [], "embed_configs": {}}	{"grid": {"cols": 12, "gap_px": 8, "row_height_px": 80}, "panels": [], "version": 1}
78f24ff3-9319-4fc4-905d-634cb8b226b0	New thesis	<div class="te-thesis-document"><p></p></div>	{commodity,global}	active	2026-04-05 18:28:52.398775+01	2026-04-05 18:28:52.43571+01	\N	{"claim": "", "flagged": [{"beta": 1.0506, "name": "WTI Crude Oil", "layer": 1, "source": "ols", "p_value": 0, "amplifier": true, "ci_95_low": 8.98, "r_squared": 0.9396, "series_id": "CM.WTI", "ci_95_high": 12.04, "regime_note": null, "transmission": null, "importance_score": 0.9396, "parent_series_id": null, "predicted_move_pct": 10.51}, {"beta": null, "name": null, "layer": 1, "source": "static_graph", "p_value": null, "amplifier": true, "ci_95_low": null, "r_squared": null, "series_id": "RATES.BREAKEVEN", "ci_95_high": null, "regime_note": "Rates volatility currently ELEVATED — this rates relationship is amplified", "transmission": null, "importance_score": 0.4, "parent_series_id": null, "predicted_move_pct": null}, {"beta": null, "name": null, "layer": 1, "source": "static_graph", "p_value": null, "amplifier": false, "ci_95_low": null, "r_squared": null, "series_id": "FX.DXY", "ci_95_high": null, "regime_note": "Dollar strength currently ELEVATED — this FX relationship is amplified", "transmission": null, "importance_score": 0.4, "parent_series_id": null, "predicted_move_pct": null}, {"beta": null, "name": null, "layer": 1, "source": "static_graph", "p_value": null, "amplifier": true, "ci_95_low": null, "r_squared": null, "series_id": "MACRO.CPI", "ci_95_high": null, "regime_note": null, "transmission": null, "importance_score": 0.4, "parent_series_id": null, "predicted_move_pct": null}, {"beta": 0.2405, "name": "Energy Select Sector SPDR", "layer": 1, "source": "ols", "p_value": 0.0005, "amplifier": true, "ci_95_low": 1.05, "r_squared": 0.2868, "series_id": "EQ.XLE", "ci_95_high": 3.77, "regime_note": "Equity volatility currently ELEVATED — this equity relationship is amplified", "transmission": null, "importance_score": 0.0829, "parent_series_id": null, "predicted_move_pct": 2.41}, {"beta": -0.1891, "name": "DAX", "layer": 1, "source": "ols", "p_value": 0, "amplifier": false, "ci_95_low": -2.62, "r_squared": 0.3433, "series_id": "EQ.DAX", "ci_95_high": -1.16, "regime_note": "Equity volatility currently ELEVATED — this equity relationship is amplified", "transmission": null, "importance_score": 0.0779, "parent_series_id": null, "predicted_move_pct": -1.89}, {"beta": 0.2219, "name": "Shell plc", "layer": 1, "source": "ols", "p_value": 0.0021, "amplifier": true, "ci_95_low": 0.8, "r_squared": 0.2349, "series_id": "EQ.SHEL", "ci_95_high": 3.64, "regime_note": "Equity volatility currently ELEVATED — this equity relationship is amplified", "transmission": null, "importance_score": 0.0626, "parent_series_id": null, "predicted_move_pct": 2.22}, {"beta": -0.1762, "name": "Euro Stoxx 50", "layer": 1, "source": "ols", "p_value": 0, "amplifier": false, "ci_95_low": -2.57, "r_squared": 0.2823, "series_id": "EQ.SX7E", "ci_95_high": -0.95, "regime_note": "Equity volatility currently ELEVATED — this equity relationship is amplified", "transmission": null, "importance_score": 0.0596, "parent_series_id": null, "predicted_move_pct": -1.76}, {"beta": 0.7185, "name": "CBOE Volatility Index", "layer": 2, "source": "ols", "p_value": 0.0944, "amplifier": true, "ci_95_low": -1.3, "r_squared": 0.0858, "series_id": "EQ.VIX", "ci_95_high": 16.4, "regime_note": "Equity volatility currently ELEVATED — this equity relationship is amplified", "transmission": null, "importance_score": 0.0544, "parent_series_id": "CM.WTI", "predicted_move_pct": 7.55}, {"beta": -0.134, "name": "STOXX Europe 600", "layer": 1, "source": "ols", "p_value": 0, "amplifier": false, "ci_95_low": -1.96, "r_squared": 0.2636, "series_id": "EQ.STOXX600", "ci_95_high": -0.72, "regime_note": "Equity volatility currently ELEVATED — this equity relationship is amplified", "transmission": null, "importance_score": 0.0424, "parent_series_id": null, "predicted_move_pct": -1.34}, {"beta": -0.1105, "name": "FTSE 100", "layer": 1, "source": "ols", "p_value": 0.0006, "amplifier": false, "ci_95_low": -1.73, "r_squared": 0.1909, "series_id": "EQ.FTSE", "ci_95_high": -0.47, "regime_note": "Equity volatility currently ELEVATED — this equity relationship is amplified", "transmission": null, "importance_score": 0.0252, "parent_series_id": null, "predicted_move_pct": -1.1}, {"beta": 0.2198, "name": "HY-IG OAS Spread (computed)", "layer": 1, "source": "ols", "p_value": 0.1069, "amplifier": true, "ci_95_low": -0.47, "r_squared": 0.0919, "series_id": "CREDIT.IG_HY_DIFF", "ci_95_high": 4.87, "regime_note": null, "transmission": null, "importance_score": 0.0202, "parent_series_id": null, "predicted_move_pct": 2.2}, {"beta": 0.1839, "name": "Wheat Futures", "layer": 2, "source": "ols", "p_value": 0.0285, "amplifier": true, "ci_95_low": 0.2, "r_squared": 0.1478, "series_id": "CM.WHEAT", "ci_95_high": 3.66, "regime_note": null, "transmission": null, "importance_score": 0.02, "parent_series_id": "CM.WTI", "predicted_move_pct": 1.93}, {"beta": 0.1768, "name": "ICE BofA US HY Corporate OAS", "layer": 2, "source": "ols", "p_value": 0.0683, "amplifier": true, "ci_95_low": -0.14, "r_squared": 0.0999, "series_id": "CREDIT.HY_OAS", "ci_95_high": 3.86, "regime_note": null, "transmission": null, "importance_score": 0.013, "parent_series_id": "CM.WTI", "predicted_move_pct": 1.86}, {"beta": -0.0394, "name": "iShares Euro High Yield Corporate Bond ETF", "layer": 2, "source": "ols", "p_value": 0, "amplifier": false, "ci_95_low": -0.54, "r_squared": 0.3758, "series_id": "EQ.IHYG", "ci_95_high": -0.28, "regime_note": "Equity volatility currently ELEVATED — this equity relationship is amplified", "transmission": null, "importance_score": 0.0129, "parent_series_id": "CM.WTI", "predicted_move_pct": -0.41}, {"beta": -0.0304, "name": "iShares Euro Corporate Bond ETF", "layer": 2, "source": "ols", "p_value": 0, "amplifier": false, "ci_95_low": -0.46, "r_squared": 0.3347, "series_id": "EQ.IEAC", "ci_95_high": -0.18, "regime_note": "Equity volatility currently ELEVATED — this equity relationship is amplified", "transmission": null, "importance_score": 0.009, "parent_series_id": "CM.WTI", "predicted_move_pct": -0.32}], "trigger": "", "tensions": [], "addressed": [], "direction": "long", "geography": "global", "shock_pct": 10, "confidence": "moderate", "asset_class": "commodity", "consistency": "clean", "time_horizon": "medium", "focal_series_id": "CM.BRENT", "asset_expression": "", "completeness_pct": 0, "generated_statement": ""}	\N
b0b3a217-8f70-4e92-ae0a-b1fdc5028af1	New thesis	<div class="te-thesis-document"><p></p></div>	{commodity,global}	active	2026-04-07 15:28:29.058361+01	2026-04-07 15:28:29.275194+01	\N	{"claim": "", "flagged": [{"beta": 1.0506, "name": "WTI Crude Oil", "layer": 1, "source": "ols", "p_value": 0, "beta_60d": 1.0529, "amplifier": true, "beta_120d": 1.0473, "beta_252d": 1.0473, "beta_note": null, "ci_95_low": 17.95, "r_squared": 0.9396, "series_id": "CM.WTI", "beta_trend": "stable", "break_date": "2026-01-26", "ci_95_high": 24.07, "beta_60d_ci": [0.8941, 1.2116], "regime_note": null, "transmission": null, "break_detected": false, "regime_pct_90d": 50, "regime_pct_756d": 50, "importance_score": 0.9396, "parent_series_id": null, "predicted_move_pct": 21.01, "predicted_move_ewls": 21.01, "beta_trend_significant": false}, {"beta": null, "name": null, "layer": 1, "source": "static_graph", "p_value": null, "amplifier": true, "ci_95_low": null, "r_squared": null, "series_id": "RATES.BREAKEVEN", "ci_95_high": null, "regime_note": "Rates volatility at 95th percentile (3yr) — this rates relationship is structurally amplified", "transmission": null, "regime_pct_90d": null, "regime_pct_756d": null, "importance_score": 0.4, "parent_series_id": null, "predicted_move_pct": null}, {"beta": null, "name": null, "layer": 1, "source": "static_graph", "p_value": null, "amplifier": false, "ci_95_low": null, "r_squared": null, "series_id": "FX.DXY", "ci_95_high": null, "regime_note": "Dollar strength at 94th percentile (3yr) — this FX relationship is structurally amplified", "transmission": null, "regime_pct_90d": null, "regime_pct_756d": null, "importance_score": 0.4, "parent_series_id": null, "predicted_move_pct": null}, {"beta": null, "name": null, "layer": 1, "source": "static_graph", "p_value": null, "amplifier": true, "ci_95_low": null, "r_squared": null, "series_id": "MACRO.CPI", "ci_95_high": null, "regime_note": null, "transmission": null, "regime_pct_90d": null, "regime_pct_756d": null, "importance_score": 0.4, "parent_series_id": null, "predicted_move_pct": null}, {"beta": 0.2405, "name": "Energy Select Sector SPDR", "layer": 1, "source": "ols", "p_value": 0.0005, "beta_60d": 0.1948, "amplifier": true, "beta_120d": 0.2383, "beta_252d": 0.2383, "beta_note": "Structural break detected 2026-01-26 — post-break data used for projection", "ci_95_low": 2.09, "r_squared": 0.2868, "series_id": "EQ.XLE", "beta_trend": "stable", "break_date": "2026-01-26", "ci_95_high": 7.53, "beta_60d_ci": [0.0806, 0.309], "regime_note": "Equity volatility at 94th percentile (3yr) — this equity relationship is structurally amplified", "transmission": null, "break_detected": true, "regime_pct_90d": 94, "regime_pct_756d": 94, "importance_score": 0.2018, "parent_series_id": null, "predicted_move_pct": 4.81, "predicted_move_ewls": 4.81, "beta_trend_significant": false}, {"beta": -0.1891, "name": "DAX", "layer": 1, "source": "ols", "p_value": 0, "beta_60d": -0.2023, "amplifier": false, "beta_120d": -0.1891, "beta_252d": -0.1891, "beta_note": null, "ci_95_low": -5.24, "r_squared": 0.3433, "series_id": "EQ.DAX", "beta_trend": "stable", "break_date": null, "ci_95_high": -2.32, "beta_60d_ci": [-0.276, -0.1287], "regime_note": "Equity volatility at 94th percentile (3yr) — this equity relationship is structurally amplified", "transmission": null, "break_detected": false, "regime_pct_90d": 94, "regime_pct_756d": 94, "importance_score": 0.1898, "parent_series_id": null, "predicted_move_pct": -3.78, "predicted_move_ewls": -3.78, "beta_trend_significant": false}, {"beta": 0.2219, "name": "Shell plc", "layer": 1, "source": "ols", "p_value": 0.0021, "beta_60d": 0.213, "amplifier": true, "beta_120d": 0.2153, "beta_252d": 0.2153, "beta_note": null, "ci_95_low": 1.61, "r_squared": 0.2349, "series_id": "EQ.SHEL", "beta_trend": "stable", "break_date": "2026-01-26", "ci_95_high": 7.27, "beta_60d_ci": [0.0713, 0.3546], "regime_note": "Equity volatility at 94th percentile (3yr) — this equity relationship is structurally amplified", "transmission": null, "break_detected": false, "regime_pct_90d": 94, "regime_pct_756d": 94, "importance_score": 0.1526, "parent_series_id": null, "predicted_move_pct": 4.44, "predicted_move_ewls": 4.44, "beta_trend_significant": false}, {"beta": -0.1762, "name": "Euro Stoxx 50", "layer": 1, "source": "ols", "p_value": 0, "beta_60d": -0.1864, "amplifier": false, "beta_120d": -0.1748, "beta_252d": -0.1748, "beta_note": null, "ci_95_low": -5.13, "r_squared": 0.2823, "series_id": "EQ.SX7E", "beta_trend": "stable", "break_date": null, "ci_95_high": -1.91, "beta_60d_ci": [-0.2666, -0.1062], "regime_note": "Equity volatility at 94th percentile (3yr) — this equity relationship is structurally amplified", "transmission": null, "break_detected": false, "regime_pct_90d": 94, "regime_pct_756d": 94, "importance_score": 0.1454, "parent_series_id": null, "predicted_move_pct": -3.52, "predicted_move_ewls": -3.52, "beta_trend_significant": false}, {"beta": -0.134, "name": "STOXX Europe 600", "layer": 1, "source": "ols", "p_value": 0, "beta_60d": -0.1389, "amplifier": false, "beta_120d": -0.1324, "beta_252d": -0.1324, "beta_note": null, "ci_95_low": -3.92, "r_squared": 0.2636, "series_id": "EQ.STOXX600", "beta_trend": "stable", "break_date": null, "ci_95_high": -1.44, "beta_60d_ci": [-0.2008, -0.0769], "regime_note": "Equity volatility at 94th percentile (3yr) — this equity relationship is structurally amplified", "transmission": null, "break_detected": false, "regime_pct_90d": 94, "regime_pct_756d": 94, "importance_score": 0.1033, "parent_series_id": null, "predicted_move_pct": -2.68, "predicted_move_ewls": -2.68, "beta_trend_significant": false}, {"beta": 0.7185, "name": "CBOE Volatility Index", "layer": 2, "source": "ols", "p_value": 0.0944, "amplifier": true, "ci_95_low": -2.59, "r_squared": 0.0858, "series_id": "EQ.VIX", "ci_95_high": 32.79, "regime_note": "Equity volatility at 94th percentile (3yr) — this equity relationship is structurally amplified", "transmission": null, "regime_pct_90d": 94, "regime_pct_756d": 94, "importance_score": 0.0879, "parent_series_id": "CM.WTI", "predicted_move_pct": 15.1}, {"beta": -0.1105, "name": "FTSE 100", "layer": 1, "source": "ols", "p_value": 0.0006, "beta_60d": -0.1124, "amplifier": false, "beta_120d": -0.1075, "beta_252d": -0.1075, "beta_note": null, "ci_95_low": -3.47, "r_squared": 0.1909, "series_id": "EQ.FTSE", "beta_trend": "stable", "break_date": null, "ci_95_high": -0.95, "beta_60d_ci": [-0.1745, -0.0503], "regime_note": "Equity volatility at 94th percentile (3yr) — this equity relationship is structurally amplified", "transmission": null, "break_detected": false, "regime_pct_90d": 94, "regime_pct_756d": 94, "importance_score": 0.0617, "parent_series_id": null, "predicted_move_pct": -2.21, "predicted_move_ewls": -2.21, "beta_trend_significant": false}, {"beta": 0.2198, "name": "HY-IG OAS Spread (computed)", "layer": 1, "source": "ols", "p_value": 0.1069, "beta_60d": 0.251, "amplifier": true, "beta_120d": 0.2198, "beta_252d": 0.2198, "beta_note": null, "ci_95_low": -0.94, "r_squared": 0.0919, "series_id": "CREDIT.IG_HY_DIFF", "beta_trend": "stable", "break_date": null, "ci_95_high": 9.74, "beta_60d_ci": [-0.0357, 0.5377], "regime_note": "Credit stress at 2th percentile (3yr) — structurally suppressed environment for this credit relationship", "transmission": null, "break_detected": false, "regime_pct_90d": 2, "regime_pct_756d": 2, "importance_score": 0.0408, "parent_series_id": null, "predicted_move_pct": 4.4, "predicted_move_ewls": 4.4, "beta_trend_significant": false}, {"beta": 0.1839, "name": "Wheat Futures", "layer": 2, "source": "ols", "p_value": 0.0285, "amplifier": true, "ci_95_low": 0.4, "r_squared": 0.1478, "series_id": "CM.WHEAT", "ci_95_high": 7.32, "regime_note": null, "transmission": null, "regime_pct_90d": 50, "regime_pct_756d": 50, "importance_score": 0.0399, "parent_series_id": "CM.WTI", "predicted_move_pct": 3.86}, {"beta": -0.0394, "name": "iShares Euro High Yield Corporate Bond ETF", "layer": 2, "source": "ols", "p_value": 0, "amplifier": false, "ci_95_low": -1.09, "r_squared": 0.3758, "series_id": "EQ.IHYG", "ci_95_high": -0.57, "regime_note": "Equity volatility at 94th percentile (3yr) — this equity relationship is structurally amplified", "transmission": null, "regime_pct_90d": 94, "regime_pct_756d": 94, "importance_score": 0.0319, "parent_series_id": "CM.WTI", "predicted_move_pct": -0.83}, {"beta": 0.1768, "name": "ICE BofA US HY Corporate OAS", "layer": 2, "source": "ols", "p_value": 0.0683, "amplifier": true, "ci_95_low": -0.27, "r_squared": 0.0999, "series_id": "CREDIT.HY_OAS", "ci_95_high": 7.71, "regime_note": "Credit stress at 2th percentile (3yr) — structurally suppressed environment for this credit relationship", "transmission": null, "regime_pct_90d": 2, "regime_pct_756d": 2, "importance_score": 0.0262, "parent_series_id": "CM.WTI", "predicted_move_pct": 3.72}, {"beta": -0.0304, "name": "iShares Euro Corporate Bond ETF", "layer": 2, "source": "ols", "p_value": 0, "amplifier": false, "ci_95_low": -0.92, "r_squared": 0.3347, "series_id": "EQ.IEAC", "ci_95_high": -0.36, "regime_note": "Equity volatility at 94th percentile (3yr) — this equity relationship is structurally amplified", "transmission": null, "regime_pct_90d": 94, "regime_pct_756d": 94, "importance_score": 0.0219, "parent_series_id": "CM.WTI", "predicted_move_pct": -0.64}], "trigger": "", "tensions": [], "addressed": [{"beta": 1.0506, "name": "WTI Crude Oil", "source": "ols", "stance": "supports", "r_squared": 0.9396, "series_id": "CM.WTI", "user_note": "", "transmission": "As a rise in CM.BRENT prices (20.0%) is expected to increase the demand for crude oil, thereby driving up CM.WTI prices by 5.25% (CM.BRENT's beta with WTI is 1.05), supporting our investment thesis that WTI will outperform Brent crude.", "predicted_move_pct": 21.01}, {"beta": 0.2405, "name": "Energy Select Sector SPDR", "source": "ols", "stance": "challenges", "r_squared": 0.2868, "series_id": "EQ.XLE", "user_note": "", "transmission": "", "predicted_move_pct": 4.81}, {"beta": -0.1891, "name": "DAX", "source": "ols", "stance": "challenges", "r_squared": 0.3433, "series_id": "EQ.DAX", "user_note": "", "transmission": "", "predicted_move_pct": -3.78}, {"beta": 0.2219, "name": "Shell plc", "source": "ols", "stance": "supports", "r_squared": 0.2349, "series_id": "EQ.SHEL", "user_note": "", "transmission": "", "predicted_move_pct": 4.44}, {"beta": -0.1762, "name": "Euro Stoxx 50", "source": "ols", "stance": "challenges", "r_squared": 0.2823, "series_id": "EQ.SX7E", "user_note": "", "transmission": "", "predicted_move_pct": -3.52}], "direction": "long", "geography": "global", "shock_pct": 20, "confidence": "moderate", "asset_class": "commodity", "consistency": "clean", "time_horizon": "medium", "focal_series_id": "CM.BRENT", "asset_expression": "", "completeness_pct": 0, "generated_statement": ""}	\N
7928f54e-81a6-4a2d-a1dc-169a383d501b	New thesis	<div class="te-thesis-document"><p></p></div>	{commodity,global}	active	2026-04-07 15:32:54.682105+01	2026-04-07 15:32:54.696806+01	\N	{"claim": "", "flagged": [{"beta": 1.0506, "name": "WTI Crude Oil", "layer": 1, "source": "ols", "p_value": 0, "beta_60d": 1.0529, "amplifier": true, "beta_120d": 1.0473, "beta_252d": 1.0473, "beta_note": null, "ci_95_low": 17.95, "r_squared": 0.9396, "series_id": "CM.WTI", "beta_trend": "stable", "break_date": "2026-01-26", "ci_95_high": 24.07, "beta_60d_ci": [0.8941, 1.2116], "regime_note": null, "transmission": null, "break_detected": false, "regime_pct_90d": 50, "regime_pct_756d": 50, "importance_score": 0.9396, "parent_series_id": null, "predicted_move_pct": 21.01, "predicted_move_ewls": 21.01, "beta_trend_significant": false}, {"beta": null, "name": null, "layer": 1, "source": "static_graph", "p_value": null, "amplifier": true, "ci_95_low": null, "r_squared": null, "series_id": "RATES.BREAKEVEN", "ci_95_high": null, "regime_note": "Rates volatility at 95th percentile (3yr) — this rates relationship is structurally amplified", "transmission": null, "regime_pct_90d": null, "regime_pct_756d": null, "importance_score": 0.4, "parent_series_id": null, "predicted_move_pct": null}, {"beta": null, "name": null, "layer": 1, "source": "static_graph", "p_value": null, "amplifier": false, "ci_95_low": null, "r_squared": null, "series_id": "FX.DXY", "ci_95_high": null, "regime_note": "Dollar strength at 94th percentile (3yr) — this FX relationship is structurally amplified", "transmission": null, "regime_pct_90d": null, "regime_pct_756d": null, "importance_score": 0.4, "parent_series_id": null, "predicted_move_pct": null}, {"beta": null, "name": null, "layer": 1, "source": "static_graph", "p_value": null, "amplifier": true, "ci_95_low": null, "r_squared": null, "series_id": "MACRO.CPI", "ci_95_high": null, "regime_note": null, "transmission": null, "regime_pct_90d": null, "regime_pct_756d": null, "importance_score": 0.4, "parent_series_id": null, "predicted_move_pct": null}, {"beta": 0.2405, "name": "Energy Select Sector SPDR", "layer": 1, "source": "ols", "p_value": 0.0005, "beta_60d": 0.1948, "amplifier": true, "beta_120d": 0.2383, "beta_252d": 0.2383, "beta_note": "Structural break detected 2026-01-26 — post-break data used for projection", "ci_95_low": 2.09, "r_squared": 0.2868, "series_id": "EQ.XLE", "beta_trend": "stable", "break_date": "2026-01-26", "ci_95_high": 7.53, "beta_60d_ci": [0.0806, 0.309], "regime_note": "Equity volatility at 94th percentile (3yr) — this equity relationship is structurally amplified", "transmission": null, "break_detected": true, "regime_pct_90d": 94, "regime_pct_756d": 94, "importance_score": 0.2018, "parent_series_id": null, "predicted_move_pct": 4.81, "predicted_move_ewls": 4.81, "beta_trend_significant": false}, {"beta": -0.1891, "name": "DAX", "layer": 1, "source": "ols", "p_value": 0, "beta_60d": -0.2023, "amplifier": false, "beta_120d": -0.1891, "beta_252d": -0.1891, "beta_note": null, "ci_95_low": -5.24, "r_squared": 0.3433, "series_id": "EQ.DAX", "beta_trend": "stable", "break_date": null, "ci_95_high": -2.32, "beta_60d_ci": [-0.276, -0.1287], "regime_note": "Equity volatility at 94th percentile (3yr) — this equity relationship is structurally amplified", "transmission": null, "break_detected": false, "regime_pct_90d": 94, "regime_pct_756d": 94, "importance_score": 0.1898, "parent_series_id": null, "predicted_move_pct": -3.78, "predicted_move_ewls": -3.78, "beta_trend_significant": false}, {"beta": 0.2219, "name": "Shell plc", "layer": 1, "source": "ols", "p_value": 0.0021, "beta_60d": 0.213, "amplifier": true, "beta_120d": 0.2153, "beta_252d": 0.2153, "beta_note": null, "ci_95_low": 1.61, "r_squared": 0.2349, "series_id": "EQ.SHEL", "beta_trend": "stable", "break_date": "2026-01-26", "ci_95_high": 7.27, "beta_60d_ci": [0.0713, 0.3546], "regime_note": "Equity volatility at 94th percentile (3yr) — this equity relationship is structurally amplified", "transmission": null, "break_detected": false, "regime_pct_90d": 94, "regime_pct_756d": 94, "importance_score": 0.1526, "parent_series_id": null, "predicted_move_pct": 4.44, "predicted_move_ewls": 4.44, "beta_trend_significant": false}, {"beta": -0.1762, "name": "Euro Stoxx 50", "layer": 1, "source": "ols", "p_value": 0, "beta_60d": -0.1864, "amplifier": false, "beta_120d": -0.1748, "beta_252d": -0.1748, "beta_note": null, "ci_95_low": -5.13, "r_squared": 0.2823, "series_id": "EQ.SX7E", "beta_trend": "stable", "break_date": null, "ci_95_high": -1.91, "beta_60d_ci": [-0.2666, -0.1062], "regime_note": "Equity volatility at 94th percentile (3yr) — this equity relationship is structurally amplified", "transmission": null, "break_detected": false, "regime_pct_90d": 94, "regime_pct_756d": 94, "importance_score": 0.1454, "parent_series_id": null, "predicted_move_pct": -3.52, "predicted_move_ewls": -3.52, "beta_trend_significant": false}, {"beta": -0.134, "name": "STOXX Europe 600", "layer": 1, "source": "ols", "p_value": 0, "beta_60d": -0.1389, "amplifier": false, "beta_120d": -0.1324, "beta_252d": -0.1324, "beta_note": null, "ci_95_low": -3.92, "r_squared": 0.2636, "series_id": "EQ.STOXX600", "beta_trend": "stable", "break_date": null, "ci_95_high": -1.44, "beta_60d_ci": [-0.2008, -0.0769], "regime_note": "Equity volatility at 94th percentile (3yr) — this equity relationship is structurally amplified", "transmission": null, "break_detected": false, "regime_pct_90d": 94, "regime_pct_756d": 94, "importance_score": 0.1033, "parent_series_id": null, "predicted_move_pct": -2.68, "predicted_move_ewls": -2.68, "beta_trend_significant": false}, {"beta": 0.7185, "name": "CBOE Volatility Index", "layer": 2, "source": "ols", "p_value": 0.0944, "amplifier": true, "ci_95_low": -2.59, "r_squared": 0.0858, "series_id": "EQ.VIX", "ci_95_high": 32.79, "regime_note": "Equity volatility at 94th percentile (3yr) — this equity relationship is structurally amplified", "transmission": null, "regime_pct_90d": 94, "regime_pct_756d": 94, "importance_score": 0.0879, "parent_series_id": "CM.WTI", "predicted_move_pct": 15.1}, {"beta": -0.1105, "name": "FTSE 100", "layer": 1, "source": "ols", "p_value": 0.0006, "beta_60d": -0.1124, "amplifier": false, "beta_120d": -0.1075, "beta_252d": -0.1075, "beta_note": null, "ci_95_low": -3.47, "r_squared": 0.1909, "series_id": "EQ.FTSE", "beta_trend": "stable", "break_date": null, "ci_95_high": -0.95, "beta_60d_ci": [-0.1745, -0.0503], "regime_note": "Equity volatility at 94th percentile (3yr) — this equity relationship is structurally amplified", "transmission": null, "break_detected": false, "regime_pct_90d": 94, "regime_pct_756d": 94, "importance_score": 0.0617, "parent_series_id": null, "predicted_move_pct": -2.21, "predicted_move_ewls": -2.21, "beta_trend_significant": false}, {"beta": 0.2198, "name": "HY-IG OAS Spread (computed)", "layer": 1, "source": "ols", "p_value": 0.1069, "beta_60d": 0.251, "amplifier": true, "beta_120d": 0.2198, "beta_252d": 0.2198, "beta_note": null, "ci_95_low": -0.94, "r_squared": 0.0919, "series_id": "CREDIT.IG_HY_DIFF", "beta_trend": "stable", "break_date": null, "ci_95_high": 9.74, "beta_60d_ci": [-0.0357, 0.5377], "regime_note": "Credit stress at 2th percentile (3yr) — structurally suppressed environment for this credit relationship", "transmission": null, "break_detected": false, "regime_pct_90d": 2, "regime_pct_756d": 2, "importance_score": 0.0408, "parent_series_id": null, "predicted_move_pct": 4.4, "predicted_move_ewls": 4.4, "beta_trend_significant": false}, {"beta": 0.1839, "name": "Wheat Futures", "layer": 2, "source": "ols", "p_value": 0.0285, "amplifier": true, "ci_95_low": 0.4, "r_squared": 0.1478, "series_id": "CM.WHEAT", "ci_95_high": 7.32, "regime_note": null, "transmission": null, "regime_pct_90d": 50, "regime_pct_756d": 50, "importance_score": 0.0399, "parent_series_id": "CM.WTI", "predicted_move_pct": 3.86}, {"beta": -0.0394, "name": "iShares Euro High Yield Corporate Bond ETF", "layer": 2, "source": "ols", "p_value": 0, "amplifier": false, "ci_95_low": -1.09, "r_squared": 0.3758, "series_id": "EQ.IHYG", "ci_95_high": -0.57, "regime_note": "Equity volatility at 94th percentile (3yr) — this equity relationship is structurally amplified", "transmission": null, "regime_pct_90d": 94, "regime_pct_756d": 94, "importance_score": 0.0319, "parent_series_id": "CM.WTI", "predicted_move_pct": -0.83}, {"beta": 0.1768, "name": "ICE BofA US HY Corporate OAS", "layer": 2, "source": "ols", "p_value": 0.0683, "amplifier": true, "ci_95_low": -0.27, "r_squared": 0.0999, "series_id": "CREDIT.HY_OAS", "ci_95_high": 7.71, "regime_note": "Credit stress at 2th percentile (3yr) — structurally suppressed environment for this credit relationship", "transmission": null, "regime_pct_90d": 2, "regime_pct_756d": 2, "importance_score": 0.0262, "parent_series_id": "CM.WTI", "predicted_move_pct": 3.72}, {"beta": -0.0304, "name": "iShares Euro Corporate Bond ETF", "layer": 2, "source": "ols", "p_value": 0, "amplifier": false, "ci_95_low": -0.92, "r_squared": 0.3347, "series_id": "EQ.IEAC", "ci_95_high": -0.36, "regime_note": "Equity volatility at 94th percentile (3yr) — this equity relationship is structurally amplified", "transmission": null, "regime_pct_90d": 94, "regime_pct_756d": 94, "importance_score": 0.0219, "parent_series_id": "CM.WTI", "predicted_move_pct": -0.64}], "trigger": "", "tensions": [], "addressed": [{"beta": 1.0506, "name": "WTI Crude Oil", "source": "ols", "stance": "supports", "r_squared": 0.9396, "series_id": "CM.WTI", "user_note": "", "transmission": "The transmission mechanism between CM.BRENT and CM.WTI occurs through a positive covariance, as the increase in Brent crude oil prices (CM.BRENT) drives up West Texas Intermediate crude oil prices (CM.WTI), reinforcing the thesis's assumption that rising energy costs will pressure inflation expectations.", "predicted_move_pct": 21.01}, {"beta": -0.1762, "name": "Euro Stoxx 50", "source": "ols", "stance": "supports", "r_squared": 0.2823, "series_id": "EQ.SX7E", "user_note": "", "transmission": "", "predicted_move_pct": -3.52}, {"beta": -0.1105, "name": "FTSE 100", "source": "ols", "stance": "supports", "r_squared": 0.1909, "series_id": "EQ.FTSE", "user_note": "", "transmission": "", "predicted_move_pct": -2.21}, {"beta": null, "name": null, "source": "static_graph", "stance": "supports", "r_squared": null, "series_id": "MACRO.CPI", "user_note": "", "transmission": "", "predicted_move_pct": null}], "direction": "long", "geography": "global", "shock_pct": 20, "confidence": "moderate", "asset_class": "commodity", "consistency": "clean", "time_horizon": "medium", "focal_series_id": "CM.BRENT", "asset_expression": "", "completeness_pct": 0, "generated_statement": ""}	\N
\.


--
-- Data for Name: research_thesis_versions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.research_thesis_versions (id, thesis_id, version_number, version_label, content_html, metadata, tags, status, created_at, created_by, is_auto_save, canvas_layout) FROM stdin;
b0be286e-96d1-452a-92ee-154b15f4c335	f216a10e-182f-481a-856c-7d1823e1f6c6	1	Migrated from local storage	<br><p><br></p><br><br><div class="thesis-chart-embed" contenteditable="false" data-embed-id="embed_1773258487500_g7l2e" data-type="overlaid" data-x="CM.BRENT" data-y="EQ.SPX" data-period="180" data-shock-pct="10" data-instruments="CM.BRENT,EQ.SPX"><div class="chart-embed-header"><span class="chart-embed-label">Brent Crude Oil vs S&amp;P 500 Index — Overlaid</span><div class="chart-embed-actions"><button type="button" class="chart-embed-btn chart-embed-settings">Settings</button><button type="button" class="chart-embed-btn chart-embed-refresh">Refresh</button><button type="button" class="chart-embed-btn chart-embed-remove">Remove</button></div></div><div class="chart-embed-canvas"></div><div class="chart-embed-meta">Last updated 17:08 · Brent Crude Oil vs S&amp;P 500 Index — Overlaid</div></div><p><br></p>	{}	{}	draft	2026-03-17 18:45:34.384479+00	user	f	\N
dcf3dea5-1c8d-412b-ba7d-7393c76fafdb	b0098003-6b01-449a-8d44-6e9d4aa615b0	1	Migrated from local storage	@<br><p><br></p><p><br></p><div class="thesis-chart-embed" contenteditable="false" data-embed-id="embed_1773685931714_3jh68" data-type="overlaid" data-x="CM.WTI" data-y="CM.BRENT" data-period="90" data-shock-pct="10" data-instruments="CM.WTI,CM.BRENT" data-width="600" data-height="311" data-shocks="[{&quot;instrumentId&quot;:&quot;CM.BRENT&quot;,&quot;shockPct&quot;:5}]" data-impact-mode="forward"><div class="chart-embed-header"><span class="chart-embed-label">WTI Crude Oil vs Brent Crude Oil — Overlaid</span><div class="chart-embed-actions"><button type="button" class="chart-embed-btn chart-embed-settings">Settings</button><button type="button" class="chart-embed-btn chart-embed-impact">Impact</button><button type="button" class="chart-embed-btn chart-embed-refresh">Refresh</button><button type="button" class="chart-embed-btn chart-embed-remove">Remove</button></div></div><div class="chart-impact-panel" data-chart-id="embed_1773685931714_3jh68" style=""><div class="chart-impact-header"><span class="chart-impact-title">Event Impact</span><div class="chart-impact-mode-toggle"><button type="button" class="chart-impact-mode-btn chart-impact-mode-btn--active" data-mode="forward">Forward</button><button type="button" class="chart-impact-mode-btn" data-mode="counterfactual">Counterfactual</button></div><button type="button" class="chart-impact-clear">Clear</button></div><div class="chart-impact-shocks"><div class="chart-impact-shock-row" data-shock-index="0" data-selected-id="CM.BRENT"><div class="chart-impact-shock-instrument"><input type="text" class="chart-impact-shock-input" placeholder="Instrument..." autocomplete="off"><div class="chart-impact-shock-autocomplete" style="display: none;"><div class="chart-impact-shock-autocomplete-item" data-instrument-id="CM.BRENT"><span class="chart-settings-autocomplete-id">CM.BRENT</span><span class="chart-settings-autocomplete-name">Brent Crude Oil</span></div></div></div><div class="chart-impact-shock-pct-wrap"><input type="number" class="chart-impact-shock-pct" placeholder="0" step="0.5"><span class="chart-impact-shock-pct-label">%</span></div><button type="button" class="chart-impact-shock-remove">×</button></div><div class="chart-impact-shock-row" data-shock-index="1" data-selected-id="FX.DXY"><div class="chart-impact-shock-instrument"><input type="text" class="chart-impact-shock-input" placeholder="Instrument..." autocomplete="off"><div class="chart-impact-shock-autocomplete" style="display: none;"><div class="chart-impact-shock-autocomplete-item" data-instrument-id="FX.DXY"><span class="chart-settings-autocomplete-id">FX.DXY</span><span class="chart-settings-autocomplete-name">US Dollar Index</span></div></div></div><div class="chart-impact-shock-pct-wrap"><input type="number" class="chart-impact-shock-pct" placeholder="0" step="0.5"><span class="chart-impact-shock-pct-label">%</span></div><button type="button" class="chart-impact-shock-remove">×</button></div></div><button type="button" class="chart-impact-add-shock">+ Add shock</button><div class="chart-impact-divider"></div><div class="chart-impact-results" style="display: block;"><div class="chart-impact-results-table"><div class="chart-impact-results-header"><span>Instrument</span><span>Impact</span><span>Conf</span></div><div class="chart-impact-results-row"><span class="chart-impact-results-name">WTI Crude Oil</span><span class="chart-impact-results-impact negative">-0.04%</span><span class="chart-impact-results-conf low">LOW</span></div><div class="chart-impact-results-row"><span class="chart-impact-results-name">Brent Crude Oil</span><span class="chart-impact-results-impact negative">-0.08%</span><span class="chart-impact-results-conf low">LOW</span></div></div></div><button type="button" class="chart-impact-run">Run</button></div><div class="chart-embed-canvas" style="position: relative;"></div><div class="chart-embed-meta">Last updated 18:32 · WTI Crude Oil vs Brent Crude Oil — Overlaid</div></div><p><br></p>	{}	{}	draft	2026-03-17 18:45:34.427764+00	user	f	\N
e7fa7c85-3e41-454e-96d9-3b3960050baa	b0098003-6b01-449a-8d44-6e9d4aa615b0	2	\N	@<br><p><br></p><p><br></p><p><br></p>	{"board_cards": [], "embed_configs": {}}	{}	draft	2026-03-22 14:56:16.241396+00	user	t	{"grid": {"cols": 12, "gap_px": 8, "row_height_px": 80}, "panels": [], "version": 1}
\.


--
-- Data for Name: theses; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.theses (id, thesis_id, generated_at, theme, hypothesis, full_doc, instruments, signals_used, confidence, status, outcome, closed_at, notes) FROM stdin;
1	MAN-001	2026-03-09 20:12:32.615368+00				[]	[]	\N	draft	\N	\N	\N
\.


--
-- Data for Name: thesis_outcome_paths; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.thesis_outcome_paths (id, thesis_id, series_id, predicted_move_pct, predicted_direction, horizon_days, thesis_created_at, current_move_pct, max_favourable_pct, max_adverse_pct, correct_at_30pct, correct_at_60pct, correct_at_100pct, target_reached, target_reached_at, status, last_updated) FROM stdin;
\.


--
-- Data for Name: thesis_track_record; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.thesis_track_record (id, computed_at, total_theses_tracked, total_variables_tracked, direction_acc_30pct, direction_acc_60pct, direction_acc_100pct, avg_magnitude_ratio, magnitude_ratio_p25, magnitude_ratio_p75, by_asset_class, by_focal_series) FROM stdin;
\.


--
-- Data for Name: thesis_variable_history; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.thesis_variable_history (id, thesis_id, focal_series_id, target_series_id, stance, regime_fingerprint, addressed_at) FROM stdin;
1	\N	CM.BRENT	FX.DXY	challenges	INSUFFICIENT_DATA-SUPPRESSED-INSUFFICIENT_DATA-ELEVATED-ELEVATED-ELEVATED-INSUFFICIENT_DATA	2026-04-05 18:53:42.14673+01
2	\N	CM.BRENT	CM.WTI	supports	INSUFFICIENT_DATA-SUPPRESSED-INSUFFICIENT_DATA-ELEVATED-ELEVATED-ELEVATED-INSUFFICIENT_DATA	2026-04-07 15:28:10.002172+01
3	\N	CM.BRENT	EQ.XLE	challenges	INSUFFICIENT_DATA-SUPPRESSED-INSUFFICIENT_DATA-ELEVATED-ELEVATED-ELEVATED-INSUFFICIENT_DATA	2026-04-07 15:28:16.008643+01
4	\N	CM.BRENT	EQ.DAX	challenges	INSUFFICIENT_DATA-SUPPRESSED-INSUFFICIENT_DATA-ELEVATED-ELEVATED-ELEVATED-INSUFFICIENT_DATA	2026-04-07 15:28:18.162792+01
5	\N	CM.BRENT	EQ.SHEL	supports	INSUFFICIENT_DATA-SUPPRESSED-INSUFFICIENT_DATA-ELEVATED-ELEVATED-ELEVATED-INSUFFICIENT_DATA	2026-04-07 15:28:20.784902+01
6	\N	CM.BRENT	EQ.SX7E	challenges	INSUFFICIENT_DATA-SUPPRESSED-INSUFFICIENT_DATA-ELEVATED-ELEVATED-ELEVATED-INSUFFICIENT_DATA	2026-04-07 15:28:22.576992+01
7	\N	CM.BRENT	CM.WTI	supports	INSUFFICIENT_DATA-SUPPRESSED-INSUFFICIENT_DATA-ELEVATED-ELEVATED-ELEVATED-INSUFFICIENT_DATA	2026-04-07 15:32:35.127054+01
8	\N	CM.BRENT	EQ.SX7E	supports	INSUFFICIENT_DATA-SUPPRESSED-INSUFFICIENT_DATA-ELEVATED-ELEVATED-ELEVATED-INSUFFICIENT_DATA	2026-04-07 15:32:38.976774+01
9	\N	CM.BRENT	EQ.FTSE	supports	INSUFFICIENT_DATA-SUPPRESSED-INSUFFICIENT_DATA-ELEVATED-ELEVATED-ELEVATED-INSUFFICIENT_DATA	2026-04-07 15:32:40.866819+01
10	\N	CM.BRENT	MACRO.CPI	supports	INSUFFICIENT_DATA-SUPPRESSED-INSUFFICIENT_DATA-ELEVATED-ELEVATED-ELEVATED-INSUFFICIENT_DATA	2026-04-07 15:32:43.729995+01
\.


--
-- Name: anomalies_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.anomalies_id_seq', 1, false);


--
-- Name: articles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.articles_id_seq', 101, true);


--
-- Name: beta_metadata_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.beta_metadata_id_seq', 60, true);


--
-- Name: correlations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.correlations_id_seq', 332, true);


--
-- Name: daily_signals_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.daily_signals_id_seq', 1381, true);


--
-- Name: market_data_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.market_data_id_seq', 6367, true);


--
-- Name: pipeline_errors_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.pipeline_errors_id_seq', 122, true);


--
-- Name: positioning_signals_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.positioning_signals_id_seq', 1, false);


--
-- Name: regime_snapshots_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.regime_snapshots_id_seq', 195, true);


--
-- Name: theses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.theses_id_seq', 1, true);


--
-- Name: thesis_outcome_paths_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.thesis_outcome_paths_id_seq', 1, false);


--
-- Name: thesis_track_record_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.thesis_track_record_id_seq', 1, false);


--
-- Name: thesis_variable_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.thesis_variable_history_id_seq', 10, true);


--
-- Name: anomalies anomalies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.anomalies
    ADD CONSTRAINT anomalies_pkey PRIMARY KEY (id);


--
-- Name: articles articles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.articles
    ADD CONSTRAINT articles_pkey PRIMARY KEY (id);


--
-- Name: articles articles_url_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.articles
    ADD CONSTRAINT articles_url_key UNIQUE (url);


--
-- Name: beta_metadata beta_metadata_base_series_id_target_series_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.beta_metadata
    ADD CONSTRAINT beta_metadata_base_series_id_target_series_id_key UNIQUE (base_series_id, target_series_id);


--
-- Name: beta_metadata beta_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.beta_metadata
    ADD CONSTRAINT beta_metadata_pkey PRIMARY KEY (id);


--
-- Name: correlations correlations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.correlations
    ADD CONSTRAINT correlations_pkey PRIMARY KEY (id);


--
-- Name: daily_signals daily_signals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_signals
    ADD CONSTRAINT daily_signals_pkey PRIMARY KEY (id);


--
-- Name: factor_decomposition_cache factor_decomposition_cache_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.factor_decomposition_cache
    ADD CONSTRAINT factor_decomposition_cache_pkey PRIMARY KEY (instrument_id);


--
-- Name: instruments instruments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instruments
    ADD CONSTRAINT instruments_pkey PRIMARY KEY (id);


--
-- Name: market_data market_data_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.market_data
    ADD CONSTRAINT market_data_pkey PRIMARY KEY (id);


--
-- Name: pipeline_errors pipeline_errors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pipeline_errors
    ADD CONSTRAINT pipeline_errors_pkey PRIMARY KEY (id);


--
-- Name: positioning_signals positioning_signals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.positioning_signals
    ADD CONSTRAINT positioning_signals_pkey PRIMARY KEY (id);


--
-- Name: regime_snapshots regime_snapshots_date_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regime_snapshots
    ADD CONSTRAINT regime_snapshots_date_key UNIQUE (date);


--
-- Name: regime_snapshots regime_snapshots_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regime_snapshots
    ADD CONSTRAINT regime_snapshots_pkey PRIMARY KEY (id);


--
-- Name: research_theses research_theses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.research_theses
    ADD CONSTRAINT research_theses_pkey PRIMARY KEY (id);


--
-- Name: research_thesis_versions research_thesis_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.research_thesis_versions
    ADD CONSTRAINT research_thesis_versions_pkey PRIMARY KEY (id);


--
-- Name: research_thesis_versions research_thesis_versions_thesis_id_version_number_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.research_thesis_versions
    ADD CONSTRAINT research_thesis_versions_thesis_id_version_number_key UNIQUE (thesis_id, version_number);


--
-- Name: theses theses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.theses
    ADD CONSTRAINT theses_pkey PRIMARY KEY (id);


--
-- Name: thesis_outcome_paths thesis_outcome_paths_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.thesis_outcome_paths
    ADD CONSTRAINT thesis_outcome_paths_pkey PRIMARY KEY (id);


--
-- Name: thesis_outcome_paths thesis_outcome_paths_thesis_id_series_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.thesis_outcome_paths
    ADD CONSTRAINT thesis_outcome_paths_thesis_id_series_id_key UNIQUE (thesis_id, series_id);


--
-- Name: thesis_track_record thesis_track_record_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.thesis_track_record
    ADD CONSTRAINT thesis_track_record_pkey PRIMARY KEY (id);


--
-- Name: thesis_variable_history thesis_variable_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.thesis_variable_history
    ADD CONSTRAINT thesis_variable_history_pkey PRIMARY KEY (id);


--
-- Name: idx_bm_base; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_bm_base ON public.beta_metadata USING btree (base_series_id);


--
-- Name: idx_correlations_topic_series; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_correlations_topic_series ON public.correlations USING btree (topic, series_id);


--
-- Name: idx_daily_signals_data_quality; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_daily_signals_data_quality ON public.daily_signals USING btree (data_quality);


--
-- Name: idx_daily_signals_date_topic; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_daily_signals_date_topic ON public.daily_signals USING btree (date, topic);


--
-- Name: idx_factor_decomp_cache_expires; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_factor_decomp_cache_expires ON public.factor_decomposition_cache USING btree (expires_at);


--
-- Name: idx_market_data_date_series; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_market_data_date_series ON public.market_data USING btree (date, series_id);


--
-- Name: idx_pipeline_errors_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pipeline_errors_source_id ON public.pipeline_errors USING btree (source_id);


--
-- Name: idx_positioning_signals_date_series; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_positioning_signals_date_series ON public.positioning_signals USING btree (date, series_id);


--
-- Name: idx_research_theses_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_research_theses_status ON public.research_theses USING btree (status);


--
-- Name: idx_research_theses_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_research_theses_updated_at ON public.research_theses USING btree (updated_at DESC);


--
-- Name: idx_research_thesis_versions_thesis_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_research_thesis_versions_thesis_id ON public.research_thesis_versions USING btree (thesis_id);


--
-- Name: idx_theses_generated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_theses_generated_at ON public.theses USING btree (generated_at);


--
-- Name: idx_theses_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_theses_status ON public.theses USING btree (status);


--
-- Name: idx_top_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_top_status ON public.thesis_outcome_paths USING btree (status);


--
-- Name: idx_top_thesis; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_top_thesis ON public.thesis_outcome_paths USING btree (thesis_id);


--
-- Name: idx_tvh_focal; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tvh_focal ON public.thesis_variable_history USING btree (focal_series_id);


--
-- Name: idx_tvh_target; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tvh_target ON public.thesis_variable_history USING btree (target_series_id);


--
-- Name: research_thesis_versions research_thesis_versions_thesis_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.research_thesis_versions
    ADD CONSTRAINT research_thesis_versions_thesis_id_fkey FOREIGN KEY (thesis_id) REFERENCES public.research_theses(id) ON DELETE CASCADE;


--
-- Name: thesis_outcome_paths thesis_outcome_paths_thesis_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.thesis_outcome_paths
    ADD CONSTRAINT thesis_outcome_paths_thesis_id_fkey FOREIGN KEY (thesis_id) REFERENCES public.research_theses(id) ON DELETE CASCADE;


--
-- Name: thesis_variable_history thesis_variable_history_thesis_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.thesis_variable_history
    ADD CONSTRAINT thesis_variable_history_thesis_id_fkey FOREIGN KEY (thesis_id) REFERENCES public.research_theses(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--


