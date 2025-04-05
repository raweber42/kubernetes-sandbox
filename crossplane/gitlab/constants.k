import gitlab_crossplane_io.v1alpha1 as gc

schema Team:
    name: str

teams: [Team] = [ # TODO: Which teams should we deploy this for? Double check
    {name = "team_one"}
    {name = "team_two"}
    {name = "team_three"}
]

# TODO: Import already existing groups
groups: [gc.Group]  = [
  {
    metadata.name = "{}".format(team.name)
    spec.deletionPolicy = "Orphan"
    spec.forProvider.autoDevopsEnabled = False
    spec.forProvider.visibility = "internal"
    spec.forProvider.path = "/{}".format(team.name)
    spec.providerConfigRef.name = "provider-gitlab"
  } for team in teams
]

group_argo_access_tokens: [gc.GroupAccessToken] = [
  {
    metadata.name = "{}-argo-access-token".format(group.metadata.name)
    spec.deletionPolicy = "Delete"
    spec.providerConfigRef.name = "provider-gitlab"
    spec.forProvider.accessLevel = 20 # Reporter
    spec.forProvider.name = "argocd"
    spec.forProvider.groupIdRef.name = group.metadata.name
    spec.forProvider.scopes = ["read_repository"]
    spec.writeConnectionSecretToRef.name = "{}-argo-access-token-credentials".format(group.metadata.name)
    spec.writeConnectionSecretToRef.namespace = "crossplane-system"
  } for group in groups
]
