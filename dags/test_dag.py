from airflow.providers.cncf.kubernetes.operators.kubernetes_pod import KubernetesPodOperator
from airflow import DAG
from datetime import datetime

default_args = {
    'owner': 'airflow',
    'start_date': datetime(2023, 1, 1),
}

with DAG('test_k8s_dag', default_args=default_args, schedule_interval=None) as dag:

    k8s_task = KubernetesPodOperator(
        namespace='default',
        image='python:3.8-slim',
        cmds=["python", "-c"],
        arguments=["print('Hello from Kubernetes Pod Operator')"],
        name="airflow-test-pod",
        task_id="pod_task",
        is_delete_operator_pod=True,
        get_logs=True,
    )
