from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Configuración del backend. Ver ARCHITECTURE.md §6.

    Todo lo que necesita un secreto de servidor vive acá: la service_role key
    de Supabase (para escribir subscriptions/placa_events saltando RLS) y las
    credenciales de Mercado Pago. El cliente Flutter nunca ve nada de esto.
    """

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    environment: str = "development"

    supabase_url: str = "http://localhost:54321"
    supabase_service_role_key: str = "local-dev-service-role-key"

    # Verificación de JWT: proyectos nuevos de Supabase emiten JWT asimétricos
    # (RS256/ES256) con JWKS publicado; proyectos legacy usan HS256 con un
    # secreto compartido. Se intenta JWKS primero y se cae a HS256 si está
    # configurado — ver app/deps.py.
    supabase_jwt_secret: str | None = None

    mercadopago_access_token: str = "TEST-local-dev-token"
    mercadopago_webhook_secret: str = "local-dev-webhook-secret"

    @property
    def supabase_jwks_url(self) -> str:
        return f"{self.supabase_url}/auth/v1/.well-known/jwks.json"

    @property
    def supabase_rest_url(self) -> str:
        return f"{self.supabase_url}/rest/v1"


@lru_cache
def get_settings() -> Settings:
    return Settings()
