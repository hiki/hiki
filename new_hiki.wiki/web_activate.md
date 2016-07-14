# new_hiki
gem化しつつあるhikiをapache上で動かすことを考える．
- passenger
  - installが中途半．下記参照
  - 結局，rackupでの起動ができずに終了．
- hiki.cgi
  - $LOAD_PATHにlibが明示されてないので，いれた．
  - gem filesが軒並みLoadError.
    - gemのpathかな．．．

Mac OS X 10.7.5 (LION)でRuby on Railsの実行環境を構築する
http://kanjuku-tomato.blogspot.jp/2013/01/mac-os-x-1075-lionruby-on-railsweb.html
```
   925	11:39	passenger-install-apache2-module
   926	11:46	ls /etc/apache2/users/
   927	11:46	sudo emacs /etc/apache2/users/passenger.conf
   928	11:47	sudo apachectl restart
```

```
% passenger-install-apache2-module
```


```
% cd /etc/apache2/users
% sudo vim passenger.conf
```

```
   LoadModule passenger_module /usr/local/Cellar/passenger/5.0.20/libexec/buildout/apache2/mod_passenger.so
   <IfModule mod_passenger.c>
     PassengerRoot /usr/local/Cellar/passenger/5.0.20/libexec/src/ruby_supportlib/phusion_passenger/locations.ini
     PassengerDefaultRuby /usr/local/Cellar/ruby/2.2.2/bin/ruby
   </IfModule>
```

passengerによるrackup起動は成功しているようであるが，
gemとしてhikiがうまくinstallされてないという

```
Web application could not be started
It looks like Bundler could not find a gem. Maybe you didn't install all the gems that this application needs. To install your gems, please run:

bundle install
If that didn't work, then the problem is probably caused by your application being run under a different environment than it's supposed to. Please check the following:

Is this app supposed to be run as the bob user?
Is this app being run on the correct Ruby interpreter? Below you will see which Ruby interpreter Phusion Passenger attempted to use.
-------- The exception is as follows: -------
```
がでる．
