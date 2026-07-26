{% macro get_trip_duration_minutes(pickup_datetime, dropoff_datetime) -%}

    {% if target.type == "bigquery" %}
        timestamp_diff({{ dropoff_datetime }}, {{ pickup_datetime }}, minute)
    {% elif target.type == "duckdb" %}
        date_diff('minute', {{ pickup_datetime }}, {{ dropoff_datetime }})
    {% endif %}

{%- endmacro %}
