import 'package:get_it/get_it.dart';

final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  //get articles section
  // sl.registerFactory<HomeBloc>(
  //     () => HomeBloc(sl<GetTopArticleUseCase>(), sl<GetAllArticleUseCase>()));
  // sl.registerLazySingleton<GetTopArticleUseCase>(
  //     () => GetTopArticleUseCase(sl<ArticleRepository>()));
  // sl.registerLazySingleton<GetAllArticleUseCase>(
  //     () => GetAllArticleUseCase(sl<ArticleRepository>()));
  // sl.registerLazySingleton<ArticleRepository>(
  //     () => ArticleRepositoryImpl(sl<ArticleService>()));
  // sl.registerLazySingleton<ArticleService>(() => ArticleServiceImpl());
}
