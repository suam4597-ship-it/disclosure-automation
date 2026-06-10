defmodule DisclosureAutomation.Repo.Migrations.CreateIssuersAndCanonicalItemEvidence do
  use Ecto.Migration

  # Gap G1/G2 alignment (docs/blueprint/schema_gap_analysis.md):
  # issuer registry for cross-source company resolution, and an
  # item <-> raw-document evidence link with match tracing so future
  # cross-source dedup can merge stories without losing provenance.
  # Additive only: no existing table or behavior changes.

  def up do
    create table(:issuers, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :canonical_name, :text, null: false
      add :lei, :string

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:issuers, [:lei])

    create table(:issuer_identifiers, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :issuer_id, references(:issuers, type: :uuid, on_delete: :delete_all), null: false
      add :kind, :string, null: false
      add :value, :string, null: false
      add :exchange, :string
      add :language, :string

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:issuer_identifiers, [:kind, :value, :exchange],
             name: :issuer_identifiers_kind_value_exchange_uidx
           )

    create index(:issuer_identifiers, [:value, :kind])
    create index(:issuer_identifiers, [:issuer_id])

    create constraint(:issuer_identifiers, :issuer_identifiers_kind_check,
             check: "kind in ('ticker', 'isin', 'alias', 'local_code')"
           )

    create table(:canonical_item_evidence, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")

      add :canonical_feed_item_id,
          references(:canonical_feed_items, type: :uuid, on_delete: :delete_all),
          null: false

      add :raw_document_id, references(:raw_documents, type: :uuid, on_delete: :restrict),
        null: false

      add :match_method, :string, null: false
      add :confidence, :decimal, precision: 4, scale: 3, null: false
      add :is_primary, :boolean, null: false, default: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:canonical_item_evidence, [:canonical_feed_item_id, :raw_document_id],
             name: :canonical_item_evidence_pair_uidx
           )

    create unique_index(:canonical_item_evidence, [:canonical_feed_item_id],
             where: "is_primary",
             name: :canonical_item_evidence_one_primary_uidx
           )

    create index(:canonical_item_evidence, [:raw_document_id])

    create constraint(:canonical_item_evidence, :canonical_item_evidence_match_method_check,
             check: "match_method in ('exact_hash', 'minhash_lsh', 'semantic', 'manual')"
           )

    create constraint(:canonical_item_evidence, :canonical_item_evidence_confidence_check,
             check: "confidence >= 0 and confidence <= 1"
           )

    alter table(:canonical_feed_items) do
      add :issuer_id, references(:issuers, type: :uuid, on_delete: :nilify_all)
    end

    create index(:canonical_feed_items, [:issuer_id, :published_at])
  end

  def down do
    alter table(:canonical_feed_items) do
      remove :issuer_id
    end

    drop_if_exists table(:canonical_item_evidence)
    drop_if_exists table(:issuer_identifiers)
    drop_if_exists table(:issuers)
  end
end
