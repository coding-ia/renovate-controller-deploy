module.exports = {
  endpoint: '{{.Endpoint}}',
  token: '{{.InstallationToken}}',
  platform: 'github',
  onboardingConfig: {
    extends: ['config:recommended', ':disableDependencyDashboard', 'group:allNonMajor'],
  },
  onboardingConfigFileName: '.github/renovate.json',
  repositories: [{{range $index, $repo := .Repositories}}{{if $index}}, {{end}}"{{$repo}}"{{end}}],
  gitAuthor: 'Development Bot <dev-bot@my-software-company.com>',
  username: 'Coding-IA Test[bot]'
}