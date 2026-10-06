-- CuyCash · esquema de la base de identidad y cuentas
--
-- ARCHIVO GENERADO. No editar a mano.
-- Se produce con:  .venv/bin/python scripts/dump_schema.py > schema.sql
-- La fuente de verdad son los modelos en app/db/models.py.
--
-- Diseño y justificación de cada decisión: docs/modelo-datos.md


CREATE TABLE lockouts (
	id VARCHAR(36) NOT NULL, 
	subject_type VARCHAR(10) NOT NULL, 
	subject_value VARCHAR(128) NOT NULL, 
	level INTEGER NOT NULL, 
	locked_until TIMESTAMP WITH TIME ZONE, 
	updated_at TIMESTAMP WITH TIME ZONE NOT NULL, 
	PRIMARY KEY (id), 
	UNIQUE (subject_type, subject_value)
)

;
CREATE INDEX ix_lockouts_subject_type ON lockouts (subject_type);
CREATE INDEX ix_lockouts_subject_value ON lockouts (subject_value);


CREATE TABLE login_attempts (
	id VARCHAR(36) NOT NULL, 
	dni VARCHAR(8) NOT NULL, 
	device_id VARCHAR(128) NOT NULL, 
	succeeded BOOLEAN NOT NULL, 
	created_at TIMESTAMP WITH TIME ZONE NOT NULL, 
	PRIMARY KEY (id)
)

;
CREATE INDEX ix_login_attempts_created_at ON login_attempts (created_at);
CREATE INDEX ix_login_attempts_device_id ON login_attempts (device_id);
CREATE INDEX ix_login_attempts_dni ON login_attempts (dni);


CREATE TABLE otp_challenges (
	id VARCHAR(36) NOT NULL, 
	purpose VARCHAR(20) NOT NULL, 
	identifier VARCHAR(255) NOT NULL, 
	user_id VARCHAR(36), 
	code_hash VARCHAR(64) NOT NULL, 
	expires_at TIMESTAMP WITH TIME ZONE NOT NULL, 
	cooldown_until TIMESTAMP WITH TIME ZONE NOT NULL, 
	attempts_left INTEGER NOT NULL, 
	resends_left INTEGER NOT NULL, 
	consumed_at TIMESTAMP WITH TIME ZONE, 
	cancelled_reason VARCHAR(20), 
	created_at TIMESTAMP WITH TIME ZONE NOT NULL, 
	PRIMARY KEY (id)
)

;
CREATE INDEX ix_otp_challenges_identifier ON otp_challenges (identifier);


CREATE TABLE otp_tickets (
	id VARCHAR(36) NOT NULL, 
	token_hash VARCHAR(64) NOT NULL, 
	purpose VARCHAR(20) NOT NULL, 
	identifier VARCHAR(255) NOT NULL, 
	user_id VARCHAR(36), 
	expires_at TIMESTAMP WITH TIME ZONE NOT NULL, 
	used_at TIMESTAMP WITH TIME ZONE, 
	checks_left INTEGER NOT NULL, 
	PRIMARY KEY (id)
)

;
CREATE UNIQUE INDEX ix_otp_tickets_token_hash ON otp_tickets (token_hash);


CREATE TABLE transactions (
	id VARCHAR(36) NOT NULL, 
	tipo VARCHAR(20) NOT NULL, 
	estado VARCHAR(12) NOT NULL, 
	idempotency_key VARCHAR(64) NOT NULL, 
	referencia VARCHAR(60), 
	request_fingerprint VARCHAR(64) NOT NULL, 
	created_at TIMESTAMP WITH TIME ZONE NOT NULL, 
	PRIMARY KEY (id), 
	CONSTRAINT ck_transactions_tipo CHECK (tipo IN ('transferencia','recarga','pago_qr','desembolso','cuota','ajuste')), 
	CONSTRAINT ck_transactions_estado CHECK (estado IN ('pendiente','confirmada','revertida'))
)

;
CREATE INDEX ix_transactions_created_at ON transactions (created_at);
CREATE UNIQUE INDEX ix_transactions_idempotency_key ON transactions (idempotency_key);


CREATE TABLE users (
	id VARCHAR(36) NOT NULL, 
	dni VARCHAR(8) NOT NULL, 
	nombres VARCHAR(120) NOT NULL, 
	apellidos VARCHAR(120) NOT NULL, 
	email VARCHAR(255) NOT NULL, 
	alias VARCHAR(60) NOT NULL, 
	pin_hash VARCHAR(255) NOT NULL, 
	pin_updated_at TIMESTAMP WITH TIME ZONE NOT NULL, 
	kyc_status VARCHAR(20) NOT NULL, 
	created_at TIMESTAMP WITH TIME ZONE NOT NULL, 
	PRIMARY KEY (id)
)

;
CREATE UNIQUE INDEX ix_users_dni ON users (dni);
CREATE INDEX ix_users_email ON users (email);


CREATE TABLE accounts (
	id VARCHAR(36) NOT NULL, 
	user_id VARCHAR(36), 
	numero VARCHAR(14) NOT NULL, 
	tipo VARCHAR(10) NOT NULL, 
	moneda VARCHAR(3) NOT NULL, 
	estado VARCHAR(10) NOT NULL, 
	nombre VARCHAR(30), 
	idempotency_key VARCHAR(64), 
	saldo_disponible BIGINT NOT NULL, 
	saldo_contable BIGINT NOT NULL, 
	created_at TIMESTAMP WITH TIME ZONE NOT NULL, 
	PRIMARY KEY (id), 
	CONSTRAINT ck_accounts_tipo CHECK (tipo IN ('ahorro','corriente','sueldo','sistema')), 
	CONSTRAINT ck_accounts_sueldo_en_soles CHECK (tipo <> 'sueldo' OR moneda = 'PEN'), 
	CONSTRAINT uq_accounts_clave_apertura UNIQUE (user_id, idempotency_key), 
	CONSTRAINT ck_accounts_moneda CHECK (moneda IN ('PEN','USD')), 
	CONSTRAINT ck_accounts_estado CHECK (estado IN ('activa','bloqueada','cerrada')), 
	CONSTRAINT ck_accounts_sistema_sin_titular CHECK ((tipo = 'sistema') = (user_id IS NULL)), 
	CONSTRAINT ck_accounts_saldo_no_negativo CHECK (tipo = 'sistema' OR saldo_disponible >= 0), 
	FOREIGN KEY(user_id) REFERENCES users (id)
)

;
CREATE UNIQUE INDEX ix_accounts_numero ON accounts (numero);
CREATE INDEX ix_accounts_user_id ON accounts (user_id);
CREATE UNIQUE INDEX ux_accounts_un_sueldo ON accounts (user_id) WHERE tipo = 'sueldo';


CREATE TABLE biometric_credentials (
	id VARCHAR(36) NOT NULL, 
	user_id VARCHAR(36) NOT NULL, 
	device_id VARCHAR(128) NOT NULL, 
	secret_hash VARCHAR(64) NOT NULL, 
	created_at TIMESTAMP WITH TIME ZONE NOT NULL, 
	revoked_at TIMESTAMP WITH TIME ZONE, 
	PRIMARY KEY (id), 
	FOREIGN KEY(user_id) REFERENCES users (id)
)

;
CREATE INDEX ix_biometric_credentials_device_id ON biometric_credentials (device_id);
CREATE UNIQUE INDEX ix_biometric_credentials_secret_hash ON biometric_credentials (secret_hash);
CREATE INDEX ix_biometric_credentials_user_id ON biometric_credentials (user_id);


CREATE TABLE devices (
	id VARCHAR(36) NOT NULL, 
	user_id VARCHAR(36) NOT NULL, 
	device_id VARCHAR(128) NOT NULL, 
	trusted_at TIMESTAMP WITH TIME ZONE NOT NULL, 
	last_seen_at TIMESTAMP WITH TIME ZONE NOT NULL, 
	nombre VARCHAR(80), 
	plataforma VARCHAR(20), 
	PRIMARY KEY (id), 
	UNIQUE (user_id, device_id), 
	FOREIGN KEY(user_id) REFERENCES users (id)
)

;
CREATE INDEX ix_devices_device_id ON devices (device_id);
CREATE INDEX ix_devices_user_id ON devices (user_id);


CREATE TABLE kyc_verifications (
	id VARCHAR(36) NOT NULL, 
	user_id VARCHAR(36) NOT NULL, 
	verdict VARCHAR(20) NOT NULL, 
	document_valid BOOLEAN NOT NULL, 
	is_live BOOLEAN NOT NULL, 
	face_match BOOLEAN NOT NULL, 
	face_distance FLOAT, 
	created_at TIMESTAMP WITH TIME ZONE NOT NULL, 
	PRIMARY KEY (id), 
	FOREIGN KEY(user_id) REFERENCES users (id)
)

;
CREATE INDEX ix_kyc_verifications_user_id ON kyc_verifications (user_id);


CREATE TABLE sessions (
	id VARCHAR(36) NOT NULL, 
	user_id VARCHAR(36) NOT NULL, 
	device_id VARCHAR(128) NOT NULL, 
	token_hash VARCHAR(64) NOT NULL, 
	created_at TIMESTAMP WITH TIME ZONE NOT NULL, 
	expires_at TIMESTAMP WITH TIME ZONE NOT NULL, 
	revoked_at TIMESTAMP WITH TIME ZONE, 
	PRIMARY KEY (id), 
	FOREIGN KEY(user_id) REFERENCES users (id)
)

;
CREATE UNIQUE INDEX ix_sessions_token_hash ON sessions (token_hash);
CREATE INDEX ix_sessions_user_id ON sessions (user_id);


CREATE TABLE beneficiaries (
	id VARCHAR(36) NOT NULL, 
	user_id VARCHAR(36) NOT NULL, 
	beneficiario_dni VARCHAR(8) NOT NULL, 
	cuenta_destino_id VARCHAR(36) NOT NULL, 
	apodo VARCHAR(40) NOT NULL, 
	created_at TIMESTAMP WITH TIME ZONE NOT NULL, 
	PRIMARY KEY (id), 
	CONSTRAINT uq_beneficiaries_user_cuenta UNIQUE (user_id, cuenta_destino_id), 
	FOREIGN KEY(user_id) REFERENCES users (id), 
	FOREIGN KEY(cuenta_destino_id) REFERENCES accounts (id)
)

;
CREATE INDEX ix_beneficiaries_beneficiario_dni ON beneficiaries (beneficiario_dni);
CREATE INDEX ix_beneficiaries_cuenta_destino_id ON beneficiaries (cuenta_destino_id);
CREATE INDEX ix_beneficiaries_user_id ON beneficiaries (user_id);


CREATE TABLE ledger_entries (
	id VARCHAR(36) NOT NULL, 
	transaction_id VARCHAR(36) NOT NULL, 
	account_id VARCHAR(36) NOT NULL, 
	direccion VARCHAR(8) NOT NULL, 
	monto BIGINT NOT NULL, 
	moneda VARCHAR(3) NOT NULL, 
	saldo_posterior BIGINT NOT NULL, 
	created_at TIMESTAMP WITH TIME ZONE NOT NULL, 
	PRIMARY KEY (id), 
	CONSTRAINT ck_ledger_direccion CHECK (direccion IN ('debito','credito')), 
	CONSTRAINT ck_ledger_monto_positivo CHECK (monto > 0), 
	FOREIGN KEY(transaction_id) REFERENCES transactions (id), 
	FOREIGN KEY(account_id) REFERENCES accounts (id)
)

;
CREATE INDEX ix_ledger_cuenta_fecha_id ON ledger_entries (account_id, created_at, id);
CREATE INDEX ix_ledger_entries_account_id ON ledger_entries (account_id);
CREATE INDEX ix_ledger_entries_created_at ON ledger_entries (created_at);
CREATE INDEX ix_ledger_entries_transaction_id ON ledger_entries (transaction_id);


CREATE TABLE transfers (
	id VARCHAR(36) NOT NULL, 
	transaction_id VARCHAR(36) NOT NULL, 
	cuenta_origen VARCHAR(36) NOT NULL, 
	cuenta_destino VARCHAR(36) NOT NULL, 
	monto BIGINT NOT NULL, 
	motivo VARCHAR(40), 
	estado VARCHAR(12) NOT NULL, 
	PRIMARY KEY (id), 
	FOREIGN KEY(transaction_id) REFERENCES transactions (id), 
	FOREIGN KEY(cuenta_origen) REFERENCES accounts (id), 
	FOREIGN KEY(cuenta_destino) REFERENCES accounts (id)
)

;
CREATE INDEX ix_transfers_cuenta_destino ON transfers (cuenta_destino);
CREATE INDEX ix_transfers_cuenta_origen ON transfers (cuenta_origen);
CREATE UNIQUE INDEX ix_transfers_transaction_id ON transfers (transaction_id);

