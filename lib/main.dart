import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('GitHub Repositories'),
        ),
        body: RepoList(),
      ),
    );
  }
}

class RepoList extends StatefulWidget {
  @override
  _RepoListState createState() => _RepoListState();
}

class _RepoListState extends State<RepoList> {
  late Future<List<Map<String, dynamic>>> _repoData;

  @override
  void initState() {
    super.initState();
    _repoData = fetchRepos();
  }

  Future<List<Map<String, dynamic>>> fetchRepos() async {
    final response =
        await http.get(Uri.parse('https://api.github.com/users/freeCodeCamp/repos'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      List<Map<String, dynamic>> repos = data.cast<Map<String, dynamic>>();

      for (int i = 0; i < repos.length; i++) {
        final commitsResponse = await http.get(Uri.parse(
            'https://api.github.com/repos/${repos[i]['full_name']}/commits'));

        if (commitsResponse.statusCode == 200) {
          List<dynamic> commitsData = json.decode(commitsResponse.body);
          if (commitsData.isNotEmpty) {
            repos[i]['last_commit'] = commitsData.first.cast<String, dynamic>();
          }
        }
      }

      return repos;
    } else {
      throw Exception('Failed to load repositories');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _repoData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          List<Map<String, dynamic>> repos =
              snapshot.data as List<Map<String, dynamic>>;

          return ListView.builder(
            itemCount: repos.length,
            itemBuilder: (context, index) {
              return RepoCard(repo: repos[index]);
            },
          );
        }
      },
    );
  }
}

class RepoCard extends StatelessWidget {
  final Map<String, dynamic> repo;

  RepoCard({required this.repo});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: ListTile(
        title: Text(repo['name'] ?? ''),
        subtitle: Text(repo['description'] ?? ''),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CommitPage(repo: repo),
            ),
          );
        },
      ),
    );
  }
}

class CommitPage extends StatelessWidget {
  final Map<String, dynamic> repo;

  CommitPage({required this.repo});

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? lastCommit = repo['last_commit'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Last Commit Info'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Repository: ${repo['name']}'),
            SizedBox(height: 8.0),
            if (lastCommit != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Author: ${lastCommit['commit']['author']['name']}'),
                  SizedBox(height: 8.0),
                  Text('Message: ${lastCommit['commit']['message']}'),
                  SizedBox(height: 8.0),
                  Text('Date: ${lastCommit['commit']['author']['date']}'),
                ],
              )
            else
              Text('No commits available.'),
          ],
        ),
      ),
    );
  }
}
